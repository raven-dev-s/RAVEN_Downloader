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
Runs yt-dlp inside the bundled Python runtime.

This script is the far side of ytdlp_bridge.py. It must not import anything
from the application, because it runs under a different Python version than
the UI process. A single JSON request arrives on stdin and JSON events leave
through stdout, one per line.
"""

import json
import sys

protocol_stream = sys.stdout
# yt-dlp and its postprocessors print to stdout. Keep that away from the protocol.
sys.stdout = sys.stderr


def emit(event, **fields):
    fields['event'] = event
    protocol_stream.write(json.dumps(fields) + '\n')
    protocol_stream.flush()


def progress_hook(data):
    emit('progress', data={
        'status': data.get('status'),
        'downloaded_bytes': data.get('downloaded_bytes'),
        'total_bytes': data.get('total_bytes'),
        'total_bytes_estimate': data.get('total_bytes_estimate'),
        'filename': data.get('filename'),
    })


def postprocessor_hook(data):
    info = data.get('info_dict') or {}
    emit('postprocessor', data={
        'status': data.get('status'),
        'postprocessor': data.get('postprocessor'),
        'info_dict': {'filepath': info.get('filepath')},
    })


def handle(request):
    import yt_dlp

    action = request['action']
    params = request.get('params') or {}
    if action == 'extract':
        with yt_dlp.YoutubeDL(params) as ydl:
            info = ydl.extract_info(request['url'], download=False)
            return ydl.sanitize_info(info)

    if action == 'download':
        params['progress_hooks'] = [progress_hook]
        params['postprocessor_hooks'] = [postprocessor_hook]
        with yt_dlp.YoutubeDL(params) as ydl:
            return ydl.download(request['urls'])

    raise ValueError('Unknown action: ' + str(action))


def main():
    request = json.load(sys.stdin)
    sys.path.insert(0, request['site_packages'])
    try:
        emit('result', value=handle(request))
    except BaseException as error:  # Report everything: the parent only sees events.
        emit('error', message=str(error) or error.__class__.__name__)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
