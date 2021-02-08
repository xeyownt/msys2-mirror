#! /bin/bash
#
# msys2-mirror.sh -- Create clone/mirror of MSYS2 repositories
#
# Author: Michaël Peeters

# set -x

BASE=$(basename "$0")
usage() {
    echo "Usage: $BASE [OPTION]... [--] [MIRROR_PATH]..."
    echo
    echo Download latest MSYS2 setup, database and files from a remote mirror.
    echo This can be used to clone a remote MSYS2 repository, for instance to
    echo install MSYS2 on offline computers.
    echo
    echo Use 'pv' if available for progress reporting.
    echo
    echo "Options:"
    echo "  -h, --help    Print this help"
    echo
    echo "  --mingw32     Download mingw32 db and files"
    echo "  --mingw32-db  Download mingw32 db only (default)"
    echo "  --no-mingw32  Do not download mingw32 db or files"
    echo
    echo "  --mingw64     Download mingw64 db and files"
    echo "  --mingw64-db  Download mingw64 db only (default)"
    echo "  --no-mingw64  Do not download mingw64 db or files"
    echo
    echo "  --msys        Download msys db and files (default)"
    echo "  --msys-db     Download msys db only"
    echo "  --no-msys     Do not download msys db or files"
    echo
    echo "Examples:"
    echo "    # Create a new local mirror (with mingw32/64 db only)"
    echo "    git clone https://github.com/xeyownt/msys2-mirror.git"
    echo "    cd msys2-mirror"
    echo "    ./$BASE"
    echo
    echo "    # Update an existing local mirror"
    echo "    cd msys2-mirror"
    echo "    git pull"
    echo "    ./$BASE"
    echo
    echo "    # Update an existing local mirror with mingw32/64"
    echo "    cd msys2-mirror"
    echo "    git pull"
    echo "    ./$BASE --mingw32 --mingw64"
    exit $1
}

die_usage() {
    CODE=$1
    shift
    echo "$BASE: Error - $@"
    usage $CODE
}

wget_pv() {
    CNT=$1
    MAX=$2
    URL=$3
    FILE=$(basename $URL)
    DST=$4
    SIZE=${5:-0}

    [ $MAX -eq 0 ] && CNT="---" || CNT=$(printf "%03d" $CNT)
    [ $MAX -eq 0 ] && MAX="---" || MAX=$(printf "%03d" $MAX)

    if [ -f $DST/$FILE ]; then
        printf "[%s/%s] Skipping %s\n" "$CNT" "$MAX" "$FILE"
    else
        if [ $SIZE -gt 0 ]; then
            printf "[%s/%s] Downloading %s (%d bytes)...\n" "$CNT" "$MAX" "$FILE" "$SIZE"
        else
            printf "[%s/%s] Downloading %s...\n" "$CNT" "$MAX" "$FILE"
        fi
        if [ $SIZE -gt 1000000 ] && command -v pv > /dev/null; then
            wget -q $URL -O - | pv -s $SIZE > $DST/$FILE
        else
            wget -q $URL -P $DST
        fi
    fi
}

download_setup()
{
    echo "Retrieving latest msys2_x86_64 setup..."
    SETUP_SIZE=$()
    # INPUT :
    #     ...
    #     <a href="msys2-x86_64-20190524.exe">msys2-x86_64-20190524.exe</a>                          24-May-2019 11:56            90688487
    #     ...
    # OUTPUT: msys2-x86_64-20190524.exe 90688487
    # echo wget -q $REPO/distrib/$ARCH/ -O -
    wget -q $REPO/distrib/$ARCH/ -O - | \
        sed -rn '/href="msys2-x86_64-.*exe"/{s/^.*href="(msys2-x86_64-[^"]*)".* ([0-9]+[MkKG]?).*$/\1 \2/;p}' | \
        sort | \
        tail -1 | \
    while read SETUP SIZE; do
        [[ $SIZE =~ .*G ]] && SIZE=$((${SIZE%%G} * 1024 * 1024 * 1024))
        [[ $SIZE =~ .*M ]] && SIZE=$((${SIZE%%M} * 1024 * 1024))
        [[ $SIZE =~ .*K ]] && SIZE=$((${SIZE%%K} * 1024))
        [[ $SIZE =~ .*k ]] && SIZE=$((${SIZE%%k} * 1024))
        wget_pv 0 0 $REPO/distrib/$ARCH/$SETUP $MIRROR $SIZE
    done
}

download_sys_arch() {
    SYS_ARCH=$1
    DB=$2
    DB_ONLY=$3

    echo "Downloading db from $REPO/$SYS_ARCH..."
    mkdir -p $MIRROR/$SYS_ARCH/
    [ -f $MIRROR/$SYS_ARCH/$DB.db.tar.gz ]     && mv $MIRROR/$SYS_ARCH/$DB.db.tar.gz     $MIRROR/$SYS_ARCH/$DB.db.tar.gz.old
    [ -f $MIRROR/$SYS_ARCH/$DB.db.tar.gz.sig ] && mv $MIRROR/$SYS_ARCH/$DB.db.tar.gz.sig $MIRROR/$SYS_ARCH/$DB.db.tar.gz.old.sig
    [ -f $MIRROR/$SYS_ARCH/$DB.files.tar.gz ]     && mv $MIRROR/$SYS_ARCH/$DB.files.tar.gz     $MIRROR/$SYS_ARCH/$DB.files.tar.gz.old
    [ -f $MIRROR/$SYS_ARCH/$DB.files.tar.gz.sig ] && mv $MIRROR/$SYS_ARCH/$DB.files.tar.gz.sig $MIRROR/$SYS_ARCH/$DB.files.tar.gz.old.sig
    rm -f $MIRROR/$SYS_ARCH/$DB.db{,.sig,.tar.gz,.tar.gz.sig}
    rm -f $MIRROR/$SYS_ARCH/$DB.files{,.sig,.tar.gz,.tar.gz.sig}
    wget -q $REPO/$SYS_ARCH/$DB.db{,.sig,.tar.gz,.tar.gz.sig} -P $MIRROR/$SYS_ARCH/
    wget -q $REPO/$SYS_ARCH/$DB.files{,.sig,.tar.gz,.tar.gz.sig} -P $MIRROR/$SYS_ARCH/

    # INPUT:
    #    %FILENAME%
    #    apr-1.7.0-1-x86_64.pkg.tar.xz
    #
    #    ...
    #
    #    %CSIZE%
    #    90676
    # OUTPUT:
    #    apr-1.7.0-1-x86_64.pkg.tar.xz 90676
    #    apr-devel-1.7.0-1-x86_64.pkg.tar.xz 282544
    #    ...
    FILES=/tmp/msys_db_files
    tar xf $MIRROR/$SYS_ARCH/$DB.db -O | sed -rn '/%FILENAME|%CSIZE/{N;s/\n/ /;p}' | sed -r '/%FILENAME/{N;s/\n/ /;s/%(FILENAME|CSIZE)% //g}' | sort > $FILES

    NFILES=$(cat $FILES | wc -l)
    CSIZE=$(awk -n '{sum += $2} END {print sum}' $FILES)
    echo "Must download $NFILES files (size = $((${CSIZE} / 1024 / 1024))MB) and their signatures."

    if [[ "$DB_ONLY" =~ "-db" ]]; then
        echo "Skipping file download (db only)."
        return 0
    fi

    cnt=0
    while read FILE CSIZE; do
        wget_pv $((++cnt)) $NFILES $REPO/$SYS_ARCH/$FILE $MIRROR/$SYS_ARCH $CSIZE
        wget_pv $cnt $NFILES $REPO/$SYS_ARCH/${FILE}.sig $MIRROR/$SYS_ARCH
    done < $FILES
    rm $FILES
}

ARCH=x86_64
REPO=http://repo.msys2.org

# Set defaults
set -- . --msys --mingw32-db --mingw64-db "$@"

for flag; do
    case $flag in
        -h | --help             ) usage 0;;
        --no-msys               ) unset MSYS ;;
        --msys    | --msys-db   ) MSYS=$flag ;;
        --no-mingw64            ) unset MINGW64 ;;
        --mingw64 | --mingw64-db) MINGW64=$flag ;;
        --no-mingw32            ) unset MINGW32 ;;
        --mingw32 | --mingw32-db) MINGW32=$flag ;;
        --                      ) shift; break;;
        -*                      ) die_usage 1 "Unknown flag '$flag'" ;;
        *                       ) MIRROR=$flag ;;
    esac
    shift
done
for path; do
    MIRROR=$path
    shift
done

if [ -z "$MIRROR" ]; then
    die_usage 1 "missing MIRROR_PATH"
fi
mkdir -p "$MIRROR" || die 2 "Cannot create path '$MIRROR'"

download_setup
[ -n "$MSYS" ]    && download_sys_arch msys/$ARCH   msys    $MSYS
[ -n "$MINGW64" ] && download_sys_arch mingw/x86_64 mingw64 $MINGW64
[ -n "$MINGW32" ] && download_sys_arch mingw/i686   mingw32 $MINGW32
