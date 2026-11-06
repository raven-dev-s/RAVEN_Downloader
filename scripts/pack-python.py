#!/usr/bin/env python3
"""
Pack Python modules into a zip archive of bytecode, as part of the build.

Python imports straight from zip archives. Thousands of small module files
compress well together, which keeps the installed app small.

Usage:
    pack-python.py SOURCE_DIR ARCHIVE [--prefix NAME] [--with-source]

SOURCE_DIR   Directory with the modules, for example lib/python3.13
ARCHIVE      Zip archive to write
--prefix     Store everything below this directory in the archive, so that
             SOURCE_DIR itself becomes an importable package of that name
--with-source
             Keep the .py files next to the bytecode. Python then still runs
             the code, if slowly, should it ever be a different version than
             the one that compiled it.

Run this with the Python version that will run the code. The bytecode uses
unchecked hashes, so it stays valid whatever times the package files carry.
"""

import argparse
import os
import py_compile
import zipfile


def pack(source_dir, archive, prefix='', with_source=False):
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for root, dirs, files in os.walk(source_dir):
            dirs[:] = sorted(d for d in dirs if d not in ('__pycache__', 'lib-dynload'))
            for name in sorted(files):
                path = os.path.join(root, name)
                member = os.path.join(prefix, os.path.relpath(path, source_dir))
                if name.endswith('.py'):
                    # zipimport looks for bytecode next to the module, not in
                    # __pycache__.
                    bytecode = path + 'c'
                    py_compile.compile(
                        path, cfile=bytecode, dfile=member, doraise=True,
                        invalidation_mode=py_compile.PycInvalidationMode.UNCHECKED_HASH)
                    z.write(bytecode, member + 'c')
                    os.remove(bytecode)
                    if with_source:
                        z.write(path, member)
                elif not name.endswith('.pyc'):
                    z.write(path, member)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source_dir')
    parser.add_argument('archive')
    parser.add_argument('--prefix', default='')
    parser.add_argument('--with-source', action='store_true')
    args = parser.parse_args()
    pack(args.source_dir, args.archive, args.prefix, args.with_source)
