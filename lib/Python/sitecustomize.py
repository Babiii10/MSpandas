# sitecustomize.py - Fix encoding issues for Windows 11
# This file is automatically imported by Python on startup

import sys
import os

# Fix: Force UTF-8 encoding for stdout/stderr to prevent Error 322
# This resolves issues with reticulate's config.py execution on Windows 11
if sys.platform == 'win32':
    # Set default encoding to UTF-8 for all I/O operations
    if hasattr(sys.stdout, 'reconfigure'):
        try:
            sys.stdout.reconfigure(encoding='utf-8', errors='replace')
            sys.stderr.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

    # Set environment variables for Python encoding
    os.environ.setdefault('PYTHONIOENCODING', 'utf-8')
    os.environ.setdefault('PYTHONUTF8', '1')

    # Fix for console encoding issues on Windows 11
    try:
        import codecs
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, errors='replace')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, errors='replace')
    except Exception:
        # If reconfiguration fails, continue anyway
        pass
