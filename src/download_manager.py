'''
 Copyright (C) 2025  RAVEN Devs

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 3.

 raven.downloader is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''

import os
import random
import shutil
import sys
import threading
import time
from pathlib import Path

current_dir = Path(__file__).parent.parent

# Builds ship yt-dlp as one zip archive; development setups may have a
# plain package directory instead.
for lib_path in (current_dir / "lib" / "python3" / "dist-packages",
                 current_dir / "lib" / "python3" / "yt_dlp.zip"):
    if lib_path.exists():
        sys.path.insert(0, str(lib_path))

# Target-specific executables and shared libraries belong below
# lib/<multiarch-triplet>.  This is Clickable's runtime layout and lets
# click-review verify that the Click architecture matches the embedded ffmpeg.
# Keep the former root-level bin directory as a fallback for already-installed
# versions of the app.
ffmpeg_candidates = []
runtime_triplet = os.environ.get("ARCH_TRIPLET")
if runtime_triplet:
    ffmpeg_candidates.append(current_dir / "lib" / runtime_triplet / "bin" / "ffmpeg")
ffmpeg_candidates.extend((current_dir / "lib").glob("*/bin/ffmpeg"))
ffmpeg_candidates.append(current_dir / "bin" / "ffmpeg")

ffmpeg_location = next((path for path in ffmpeg_candidates if path.is_file()), None)
if ffmpeg_location:
    ffmpeg_bin_path = ffmpeg_location.parent
    ffmpeg_lib_path = ffmpeg_bin_path.parent
    ld_library_path = os.environ.get("LD_LIBRARY_PATH", "")
    os.environ["LD_LIBRARY_PATH"] = (
        f"{ffmpeg_lib_path}{os.pathsep}{ld_library_path}"
        if ld_library_path else str(ffmpeg_lib_path)
    )
    os.environ["PATH"] = str(ffmpeg_bin_path) + os.pathsep + os.environ.get("PATH", "")
    os.environ["FFMPEG_BINARY"] = str(ffmpeg_location)
else:
    print("[download_manager] WARNING: embedded ffmpeg binary not found")

try:
    from .ytdlp_bridge import Runtime, find_runtime
    from .format_parser import format_filesize, parse_playlist_info, parse_video_formats
    from .storage_manager import get_storage_manager, save_list_model_data, load_list_model_data
    from .url_validator import (is_valid_playlist_url, is_valid_url, is_valid_video_url, 
                                is_valid_playlist, supports_playlists, get_platform_name)
except ImportError:
    from ytdlp_bridge import Runtime, find_runtime
    from format_parser import format_filesize, parse_playlist_info, parse_video_formats
    from storage_manager import get_storage_manager, save_list_model_data, load_list_model_data
    from url_validator import (is_valid_playlist_url, is_valid_url, is_valid_video_url, 
                               is_valid_playlist, supports_playlists, get_platform_name)

# Builds for a system Python that yt-dlp no longer supports bundle their own
# runtime. Everything else runs yt-dlp directly inside this process.
runtime_python = find_runtime(current_dir)
if runtime_python:
    yt_dlp = Runtime(runtime_python)
else:
    try:
        import yt_dlp
    except ImportError as e:
        print(f"[download_manager] WARNING: yt-dlp not installed: {e}")
        yt_dlp = None
    except Exception as e:
        print(f"[download_manager] ERROR importing yt-dlp: {e}")
        yt_dlp = None

# Connection problems worth another attempt. Everything else, such as a video
# that is private or removed, fails at once.
TRANSIENT_ERROR_MARKERS = (
    'timed out', 'timeout', 'connection', 'network', 'unreachable', 'reset by peer',
    'temporary failure', 'name resolution', 'incompleteread', 'remote end closed',
    'eof occurred', 'ssl', 'http error 5', 'http error 429', 'giving up after',
    'broken pipe',
)

# How long to wait before each further attempt, in seconds.
DOWNLOAD_RETRY_DELAYS = (3, 8, 20)
FETCH_RETRY_DELAYS = (2, 5)


def is_transient_error(message):
    """
    Tell whether an error message describes a passing connection problem.

    Args:
        message: Error text from yt-dlp

    Returns:
        True when trying again may succeed
    """
    text = str(message).lower()
    return any(marker in text for marker in TRANSIENT_ERROR_MARKERS)


class DownloadManager:
    """
    Orchestrates video downloads using yt-dlp library.
    
    Manages download lifecycle including format extraction, progress tracking,
    and post-processing. Implements singleton pattern for global access.
    """
    
    def __init__(self):
        """
        Initialize download manager with empty state.
        
        Sets up tracking structures for active downloads, progress throttling,
        and storage manager integration.
        """
        self.active_downloads = {}
        self.download_counter = 0
        self.storage = get_storage_manager()
        self.last_progress_time = {}
        self.progress_throttle = 0.1
    
    @staticmethod
    def _get_common_ydl_opts():
        """
        Generate shared yt-dlp configuration options.
        
        Returns:
            Dictionary containing common options for yt-dlp operations including
            quiet mode, SSL bypass, and user agent configuration
        """
        return {
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
            'legacy_server_connect': True,
            'user_agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'cookiesfrombrowser': None,
            # Mobile connections drop out. Give up on a stalled connection
            # sooner and let yt-dlp try again instead of waiting.
            'socket_timeout': 15,
            'retries': 10,
            'fragment_retries': 10,
            'extractor_retries': 3,
            'file_access_retries': 3,
        }
    
    def action_submit(self, url, download_type=0):
        """
        Extract video or playlist metadata from URL.
        
        Validates URL, determines content type (video/playlist), and extracts
        format information using yt-dlp. Replaces C++ downloadManager.actionSubmit().
        
        Args:
            url: Video or playlist URL to process
            download_type: Content type selector (0=single video, 1=playlist)
            
        Returns:
            Dictionary containing extracted format data and metadata, or error information
            if extraction fails. Format: {'type': 'video'|'playlist', 'data': {...}} or
            {'error': 'error message'}
        """
        try:
            if not yt_dlp:
                error_msg = 'yt-dlp is not installed'
                print(f"[action_submit] ERROR: {error_msg}")
                return {'error': error_msg}
            
            if not is_valid_url(url):
                error_msg = f'Invalid URL provided: {url}'
                print(f"[action_submit] ERROR: {error_msg}")
                return {'error': error_msg}
            
            is_playlist = is_valid_playlist_url(url)
            
            if download_type == 1 and not supports_playlists(url):
                platform = get_platform_name(url)
                error_msg = f'{platform} does not support playlist downloads'
                print(f"[action_submit] ERROR: {error_msg}")
                return {'error': error_msg}
            
            if is_playlist and download_type == 0:
                return {'error': 'playlist_as_video', 'url': url}
            
            if download_type == 1 and not is_playlist:
                platform = get_platform_name(url)
                error_msg = f'This is not a valid playlist URL for {platform}'
                print(f"[action_submit] ERROR: {error_msg}")
                return {'error': error_msg}
            
            ydl_opts = self._get_common_ydl_opts()
            ydl_opts['extract_flat'] = is_playlist
            
            info = None
            for attempt, delay in enumerate(FETCH_RETRY_DELAYS + (None,)):
                try:
                    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                        info = ydl.extract_info(url, download=False)
                    break
                except Exception as e:
                    if delay is None or not is_transient_error(e):
                        raise
                    print(f"[action_submit] Connection problem, trying again in {delay}s: {e}")
                    time.sleep(delay)
            
            if is_playlist:
                return {'type': 'playlist', 'data': parse_playlist_info(info)}
            return {'type': 'video', 'data': parse_video_formats(info)}
                    
        except Exception as e:
            error_msg = str(e)
            print(f"[action_submit] EXCEPTION: {error_msg}")
            import traceback
            traceback.print_exc()
            return {'error': error_msg}
    
    def action_download(self, video_url, options):
        """
        Execute video download with specified format and options.
        
        Starts threaded download process with progress tracking and post-processing.
        Replaces C++ downloadManager.actionDownload().
        
        Args:
            video_url: Video URL to download
            options: Download configuration dictionary:
                - format: Combined format string (e.g., "137+140")
                - indexID: Download ID for progress tracking
                - subtitle: Download subtitles flag (optional)
                - caption: Download captions flag (optional)
                - embedded: Embed subtitles flag (optional)
                - extractAudio: Keep only the audio of the download (optional)
                - expectedSizes: Expected byte size per stream, in the order of
                  the format string, to weigh their progress (optional)
                
        Returns:
            Dictionary with success status and download_id for tracking:
            {'success': True, 'download_id': int} or {'success': False, 'error': str}
        """
        try:
            if not yt_dlp:
                error_msg = 'yt-dlp is not installed'
                print(f"[action_download] ERROR: {error_msg}")
                return {'success': False, 'error': error_msg}
            
            download_id = options.get('indexID', self.download_counter)
            if 'indexID' not in options:
                self.download_counter += 1
                download_id = self.download_counter
            
            format_selector = options.get('format', 'best')
            
            # Downloads go to the cache first and move to the library once
            # complete, so the library never holds partial files.
            output_path = self.storage.get_download_path()
            output_name = '%(title)s.%(ext)s'
            
            download_subtitles = options.get('subtitle', False)
            download_captions = options.get('caption', False)
            embed_subs = options.get('embedded', False)
            
            self.last_progress_time[download_id] = {
                'progress': 0,
                'status': 'preparing',
                'timestamp': time.time()
            }
            
            # Video and audio arrive as separate streams, one after the other.
            # Progress covers all of them together, so it never jumps back.
            # yt-dlp reports streams one at a time, so the number of streams
            # comes from the format request ("audio+video") and their expected
            # sizes, where known, from the caller.
            stream_count = format_selector.split('/')[0].count('+') + 1
            expected_sizes = [int(size or 0) for size in options.get('expectedSizes') or []]
            parts = {}
            order = []
            finished_parts = set()
            shown = {'progress': 0.0}
            
            def overall_progress():
                count = max(stream_count, len(order))
                # Weigh streams by size when every size is known up front,
                # otherwise equally. Mixing both would make progress jump.
                if len(expected_sizes) >= count and all(expected_sizes[:count]):
                    weights = expected_sizes[:count]
                else:
                    weights = [1] * count
                fractions = []
                for index in range(count):
                    done, total = parts.get(order[index], (0, 0)) if index < len(order) else (0, 0)
                    fractions.append(min(1.0, done / total) if total else 0.0)
                progress = 100.0 * sum(w * f for w, f in zip(weights, fractions)) / sum(weights)
                # Size estimates of streams in fragments shift as they arrive.
                # Never show progress going backwards.
                shown['progress'] = max(shown['progress'], progress)
                return shown['progress']
            
            def progress_hook(d):
                part = str((d.get('info_dict') or {}).get('format_id') or d.get('filename') or 'single')
                if part not in order:
                    order.append(part)
                
                if d['status'] == 'downloading':
                    downloaded = d.get('downloaded_bytes') or 0
                    total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                    parts[part] = (downloaded, total)
                    self.last_progress_time[download_id] = {
                        'progress': min(99.0, overall_progress()),
                        'status': 'downloading',
                        'timestamp': time.time()
                    }
                
                elif d['status'] == 'finished':
                    size = d.get('total_bytes') or (parts.get(part) or (0, 0))[1] or 1
                    parts[part] = (size, size)
                    finished_parts.add(part)
                    filename = d.get('filename', 'Unknown')
                    print(f"[action_download] Stream downloaded: {filename}")
                    
                    all_done = len(finished_parts) >= stream_count
                    self.last_progress_time[download_id] = {
                        'progress': 99.0 if all_done else min(99.0, overall_progress()),
                        # Once every stream is in, only processing remains.
                        'status': 'processing' if all_done else 'downloading',
                        'filename': filename,
                        'timestamp': time.time()
                    }
            
            def postprocessor_hook(d):
                if d['status'] == 'finished':
                    filename = d.get('info_dict', {}).get('filepath') or 'Unknown'
                    print(f"[action_download] Post-processing step complete: {filename}")
                    
                    # Later postprocessors may still move or replace the file.
                    # download_thread reports "finished" once all of them ran.
                    self.last_progress_time[download_id] = {
                        'progress': 99.0,
                        'status': 'processing',
                        'filename': filename,
                        'timestamp': time.time()
                    }
            
            output_template = os.path.join(output_path, output_name)
            
            ydl_opts = self._get_common_ydl_opts()
            ydl_opts.update({
                'format': format_selector,
                'outtmpl': output_template,
                'progress_hooks': [progress_hook],
                'postprocessor_hooks': [postprocessor_hook],
                'quiet': False,
                'no_warnings': False,
            })
            
            ffmpeg_binary = os.environ.get("FFMPEG_BINARY")
            if ffmpeg_binary and os.path.exists(ffmpeg_binary):
                ydl_opts['ffmpeg_location'] = os.path.dirname(ffmpeg_binary)
            
            if download_subtitles or download_captions:
                ydl_opts['writesubtitles'] = True
                if download_captions:
                    ydl_opts['writeautomaticsub'] = True
                if embed_subs:
                    ydl_opts['embedsubtitles'] = True
                    ydl_opts['postprocessors'] = [{
                        'key': 'FFmpegEmbedSubtitle',
                    }]
            
            if options.get('extractAudio', False):
                # 'best' keeps the original audio stream without re-encoding it.
                ydl_opts.setdefault('postprocessors', []).append({
                    'key': 'FFmpegExtractAudio',
                    'preferredcodec': 'best',
                })
            
            def download_thread():
                for attempt, delay in enumerate(DOWNLOAD_RETRY_DELAYS + (None,)):
                    try:
                        # A new attempt resumes partial files; keep the
                        # progress shown so far.
                        parts.clear()
                        order.clear()
                        finished_parts.clear()
                        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                            ydl.download([video_url])
                        
                        filename = self.last_progress_time[download_id].get('filename', '')
                        saved = self.storage.move_to_library(filename)
                        self.last_progress_time[download_id] = {
                            'progress': 100.0,
                            'status': 'finished',
                            'filename': saved,
                            'timestamp': time.time(),
                            'success': True
                        }
                        return
                        
                    except Exception as e:
                        error_msg = str(e)
                        print(f"[action_download] Download thread error: {error_msg}")
                        if delay is not None and is_transient_error(error_msg):
                            # Partial files stay in the cache, so the next
                            # attempt continues where this one stopped.
                            self.last_progress_time[download_id] = {
                                'progress': self.last_progress_time[download_id].get('progress', 0),
                                'status': 'retrying',
                                'attempt': attempt + 2,
                                'attempts': len(DOWNLOAD_RETRY_DELAYS) + 1,
                                'timestamp': time.time()
                            }
                            time.sleep(delay)
                            continue
                        
                        self.last_progress_time[download_id] = {
                            'progress': 0,
                            'status': 'error',
                            'error': error_msg,
                            'transient': is_transient_error(error_msg),
                            'timestamp': time.time(),
                            'success': False
                        }
                        return
            
            thread = threading.Thread(target=download_thread, daemon=True)
            thread.start()
            self.active_downloads[download_id] = thread
            
            return {'success': True, 'download_id': download_id}
            
        except Exception as e:
            error_msg = str(e)
            print(f"[action_download] ERROR: {error_msg}")
            import traceback
            traceback.print_exc()
            return {'success': False, 'error': error_msg}
    
    def cancel_download(self, download_id):
        """
        Attempt to cancel an active download.
        
        Args:
            download_id: Download ID to cancel
            
        Returns:
            Dictionary with cancellation result. Note: yt-dlp does not support
            graceful cancellation, so this currently returns not-implemented error
        """
        if download_id in self.active_downloads:
            return {'success': False, 'error': 'Download cancellation not supported yet'}
        else:
            return {'success': False, 'error': 'Download not found'}
    
    def get_download_progress(self, download_id):
        """
        Retrieve current progress information for download.
        
        Args:
            download_id: Download ID to query
            
        Returns:
            Dictionary with progress data including percentage, status, and timestamps,
            or None if download not found
        """
        if download_id in self.last_progress_time:
            return self.last_progress_time[download_id]
        return None
    
    def get_version_info(self):
        """
        Get yt-dlp library version information.
        
        Returns:
            Version string if yt-dlp is available, error message otherwise
        """
        if yt_dlp:
            return yt_dlp.version.__version__
        return "yt-dlp not installed"


_manager = None

def get_manager():
    """
    Retrieve singleton instance of DownloadManager.
    
    Returns:
        Global DownloadManager instance, creating it if necessary
    """
    global _manager
    if _manager is None:
        _manager = DownloadManager()
    return _manager


def action_submit(url, download_type=0):
    """
    Extract video or playlist metadata with thumbnail caching.
    
    QML-accessible wrapper for DownloadManager.action_submit() that adds
    automatic thumbnail download and caching for video entries.
    
    Args:
        url: Video or playlist URL to process
        download_type: Content type (0=video, 1=playlist)
        
    Returns:
        Dictionary with extracted data, cached thumbnail path, and generated entry ID
    """
    manager = get_manager()
    result = manager.action_submit(url, download_type)
    
    if result and result.get('type') == 'video' and result.get('data'):
        data = result['data']
        thumbnail_url = data.get('thumbnail')
        video_id = data.get('videoUrl', url)
        
        storage = get_storage_manager()
        timestamp = int(time.time() * 1000)
        rand = random.randint(1000, 9999)
        entry_id = f"entry_{timestamp}_{rand}"
        data['entryId'] = entry_id
        
        if thumbnail_url and video_id:
            data['thumbnail'] = storage.download_thumbnail(thumbnail_url, video_id, entry_id)
    
    return result


def action_download(video_url, options):
    """
    Initiate video download with specified configuration.
    
    QML-accessible wrapper for DownloadManager.action_download().
    
    Args:
        video_url: URL to download
        options: Download configuration dictionary
        
    Returns:
        Dictionary with download start confirmation and tracking ID
    """
    manager = get_manager()
    return manager.action_download(video_url, options)


def get_download_progress(download_id):
    """
    Query download progress for tracking.
    
    QML-accessible wrapper for DownloadManager.get_download_progress().
    
    Args:
        download_id: Download ID to query
        
    Returns:
        Progress dictionary or None
    """
    manager = get_manager()
    return manager.get_download_progress(download_id)


def cancel_download(download_id):
    """
    Request download cancellation.
    
    QML-accessible wrapper for DownloadManager.cancel_download().
    
    Args:
        download_id: Download ID to cancel
        
    Returns:
        Cancellation result dictionary
    """
    manager = get_manager()
    return manager.cancel_download(download_id)

def get_yt_dlp_version():
    """
    Retrieve yt-dlp version string.
    
    QML-accessible wrapper for DownloadManager.get_version_info().
    
    Returns:
        Version string
    """
    manager = get_manager()
    return manager.get_version_info()

if __name__ != "__main__":
    pass
