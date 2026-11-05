'''
 Copyright (C) 2026  RAVEN Devs

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

"""
Drop-in stand-in for the parts of the yt_dlp module the app uses.

Current yt-dlp releases need a newer Python than Ubuntu Touch 20.04 provides,
and PyOtherSide ties the UI process to the system Python. Builds for such a
system therefore bundle a separate Python runtime holding yt-dlp, and this
module drives it through ytdlp_worker.py as a child process.
"""

import json
import os
import re
import subprocess
from pathlib import Path

RUNTIME_DIR_NAME = 'ytdlp-runtime'


class DownloadError(Exception):
    """Raised when the bundled yt-dlp reports a failure."""


def find_runtime(app_dir):
    """
    Locate the bundled Python interpreter.

    Args:
        app_dir: Application root directory

    Returns:
        Path of the interpreter, or None when this build runs yt-dlp in-process
    """
    candidates = []
    triplet = os.environ.get('ARCH_TRIPLET')
    if triplet:
        candidates.append(Path(app_dir) / 'lib' / triplet / RUNTIME_DIR_NAME / 'bin' / 'python3')
    candidates.extend((Path(app_dir) / 'lib').glob('*/' + RUNTIME_DIR_NAME + '/bin/python3'))
    return next((path for path in candidates if path.exists()), None)


class Runtime:
    """Module-like object exposing YoutubeDL and version, as yt_dlp does."""

    def __init__(self, python_path):
        self.python_path = Path(python_path)
        self.site_packages = self.python_path.parent.parent / 'site-packages'
        self.worker_path = Path(__file__).resolve().parent / 'ytdlp_worker.py'
        self.version = _Version(self)

    def YoutubeDL(self, params=None):
        return _YoutubeDL(self, params)

    def call(self, request, on_event=None):
        """
        Run one request in a worker process and wait for its result.

        Args:
            request: JSON-serializable request dictionary
            on_event: Optional callable receiving intermediate events

        Returns:
            The value of the worker's result event

        Raises:
            DownloadError: If the worker reports an error or exits without a result
        """
        request = dict(request, site_packages=str(self.site_packages))

        env = dict(os.environ)
        env.pop('PYTHONHOME', None)
        env.pop('PYTHONPATH', None)
        env['PYTHONIOENCODING'] = 'utf-8'

        # -I isolates the runtime from the UI's Python; -B stops it trying to
        # write bytecode into the read-only Click installation directory.
        process = subprocess.Popen(
            [str(self.python_path), '-I', '-B', str(self.worker_path)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            env=env,
            universal_newlines=True,
            encoding='utf-8',
        )
        process.stdin.write(json.dumps(request))
        process.stdin.close()

        outcome = None
        for line in process.stdout:
            event = json.loads(line)
            if event['event'] in ('result', 'error'):
                outcome = event
            elif on_event:
                on_event(event)

        return_code = process.wait()
        if outcome is None:
            raise DownloadError('yt-dlp stopped unexpectedly (exit code %d)' % return_code)
        if outcome['event'] == 'error':
            raise DownloadError(outcome['message'])
        return outcome['value']


class _Version:
    """Reads the version from the installed package, without starting yt-dlp."""

    def __init__(self, runtime):
        self._runtime = runtime

    @property
    def __version__(self):
        version_file = self._runtime.site_packages / 'yt_dlp' / 'version.py'
        match = re.search(r"^__version__\s*=\s*'([^']+)'", version_file.read_text(encoding='utf-8'), re.M)
        return match.group(1) if match else 'unknown'


class _YoutubeDL:
    """The subset of yt_dlp.YoutubeDL used by DownloadManager."""

    def __init__(self, runtime, params):
        self._runtime = runtime
        self._params = dict(params or {})
        # Callbacks stay in this process; the worker forwards their data as events.
        self._progress_hooks = self._params.pop('progress_hooks', [])
        self._postprocessor_hooks = self._params.pop('postprocessor_hooks', [])

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        return False

    def extract_info(self, url, download=False):
        return self._runtime.call({'action': 'extract', 'url': url, 'params': self._params})

    def download(self, urls):
        return self._runtime.call(
            {'action': 'download', 'urls': list(urls), 'params': self._params},
            self._dispatch,
        )

    def _dispatch(self, event):
        hooks = {
            'progress': self._progress_hooks,
            'postprocessor': self._postprocessor_hooks,
        }.get(event['event'], [])
        for hook in hooks:
            hook(event['data'])
