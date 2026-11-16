"""Compatibility shim: build the current SMTP-capable local MCP package.

The actual SMTP tool remains disabled unless the Windows user opted in.
No mail or credential data is included in the ZIP.
"""
from smtp_package_local import build

if __name__ == '__main__':
    print(build())
