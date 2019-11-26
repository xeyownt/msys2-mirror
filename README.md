# Overview
This package provides a simple script to build a local MSYS2 repository
by cloning a remote mirror. This script checks for the latest setup,
database and package files and download them as necessary. This can be
used to install or update MSYS2 on offline computers.

The script can download the database and packages for the three subsystems
**msys**, **mingw32** and **mingw64**. By default however the script will 
not download th packages for the mingw32/64 subsystems. This is to minimize
the size of the local mirror.

If available, the script uses `pv` for progress reporting.

# Options

```bash
--mingw32     Download mingw32 db and files
--mingw32-db  Download mingw32 db only (default)
--no-mingw32  Do not download mingw32 db or files

--mingw64     Download mingw64 db and files
--mingw64-db  Download mingw64 db only (default)
--no-mingw64  Do not download mingw64 db or files

--msys        Download msys db and files (default)
--msys-db     Download msys db only
--no-msys     Do not download msys db or files
```

# Examples

To create a new local mirror (with mingw32/64 db only):
```bash
    git clone https://github.com/xeyownt/msys2-mirror.git
    cd msys2-mirror
    ./msys2-mirror.sh
```

To update an existing local mirror:
```bash
    cd msys2-mirror
    git pull
    ./msys2-mirror.sh
```

Same, but including the subsystems mingw32/64:
```bash
cd msys2-mirror
git pull
./msys2-mirror.sh --mingw32 --mingw64
```
