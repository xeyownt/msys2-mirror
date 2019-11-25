#! /bin/bash
#
# msys2-mirror.sh -- Create clone/mirror of MSYS2 repositories
#
# Author: Michaël Peeters

# set -x

BASE=$(basename "$0")
usage() {
    echo "Usage: $BASE [--msys | --mingw64 | --mingw32] [--db] <MIRROR_PATH>"
    echo
    echo "    Example: $BASE ."
    exit $1
}

die_usage() {
    CODE=$1
    shift
    echo "$BASE: Error - $@"
    usage $CODE
}

if [ -z "$1" ]; then
    die_usage 1 "missing MIRROR_PATH"
fi

MIRROR=
DB_ONLY=false
ARCH=x86_64
REPO=http://repo.msys2.org

SYS_ARCH=msys/x86_64
DB=msys

for flag; do
    case $flag in
        --msys)    SYS_ARCH=msys/x86_64; DB=msys ;;
        --mingw64) SYS_ARCH=mingw/x86_64; DB=mingw64 ;;
        --mingw32) SYS_ARCH=mingw/i686; DB=mingw32 ;;
        --db)      DB_ONLY=true ;;
        -*)        die_usage 1 "Unknown flag '$flag'" ;;
        *)         MIRROR=$flag ;;
    esac
    shift
done

if [ -z "$MIRROR" ]; then
    die_usage 1 "missing MIRROR_PATH"
fi
mkdir -p "$MIRROR" || die 2 "Cannot create path '$MIRROR'"

wget_pv() {
    CNT=$1
    MAX=$2
    URL=$3
    FILE=$(basename $URL)
    DST=$4
    SIZE=$5

    [ $MAX -eq 0 ] && CNT="---" || CNT=$(printf "%03d" $CNT)
    [ $MAX -eq 0 ] && MAX="---" || MAX=$(printf "%03d" $MAX)

    if [ -f $DST/$FILE ]; then
        printf "[%s/%s] Skipping %s\n" "$CNT" "$MAX" "$FILE"
    else
        printf "[%s/%s] Downloading %s (%d bytes)...\n" "$CNT" "$MAX" "$FILE" "$SIZE"
        if [ -n "$SIZE" -a $SIZE -gt 1000000 ] && command -v pv > /dev/null; then
            wget -q $URL -O - | pv -s $SIZE > $DST/$FILE
        else
            wget -q $URL -P $DST
        fi
    fi
}

echo "Retrieving latest msys2_x86_64 setup..."
SETUP_SIZE=$()
wget -q $REPO/distrib/$ARCH/ -O - | \
    sed -rn '/href="msys2-x86_64-/{s/^.*href="(msys2-x86_64-[^"]*)".* ([0-9]+).*$/\1 \2/;p}' | \
    sort | \
    tail -1 | \
while read SETUP SIZE; do
    wget_pv 0 0 $REPO/distrib/$ARCH/$SETUP $MIRROR $SIZE
done

echo "Downloading db and files for $REPO/$SYS_ARCH..."
mkdir -p $MIRROR/$SYS_ARCH/
[ -f $MIRROR/$SYS_ARCH/$DB.db.tar.gz ]     && mv $MIRROR/$SYS_ARCH/$DB.db.tar.gz     $MIRROR/$SYS_ARCH/$DB.db.tar.gz.old
[ -f $MIRROR/$SYS_ARCH/$DB.db.tar.gz.sig ] && mv $MIRROR/$SYS_ARCH/$DB.db.tar.gz.sig $MIRROR/$SYS_ARCH/$DB.db.tar.gz.old.sig
[ -f $MIRROR/$SYS_ARCH/$DB.files.tar.gz ]     && mv $MIRROR/$SYS_ARCH/$DB.files.tar.gz     $MIRROR/$SYS_ARCH/$DB.files.tar.gz.old
[ -f $MIRROR/$SYS_ARCH/$DB.files.tar.gz.sig ] && mv $MIRROR/$SYS_ARCH/$DB.files.tar.gz.sig $MIRROR/$SYS_ARCH/$DB.files.tar.gz.old.sig
rm -f $MIRROR/$SYS_ARCH/$DB.db{,.sig,.tar.gz,.tar.gz.sig}
rm -f $MIRROR/$SYS_ARCH/$DB.files{,.sig,.tar.gz,.tar.gz.sig}
wget -q $REPO/$SYS_ARCH/$DB.db{,.sig,.tar.gz,.tar.gz.sig} -P $MIRROR/$SYS_ARCH/
wget -q $REPO/$SYS_ARCH/$DB.files{,.sig,.tar.gz,.tar.gz.sig} -P $MIRROR/$SYS_ARCH/

FILES=/tmp/msys_db_files
tar xf $MIRROR/$SYS_ARCH/$DB.db -O | sed -rn '/%FILENAME|%CSIZE/{N;s/\n/ /;p}' | sed -r '/%FILENAME/{N;s/\n/ /;s/%(FILENAME|CSIZE)% //g}' | sort > $FILES

NFILES=$(cat $FILES | wc -l)
CSIZE=$(awk -n '{sum += $2} END {print sum}' $FILES)
echo "Must download $NFILES files (size = $((${CSIZE} / 1024 / 1024))MB) and their signatures."

if $DB_ONLY; then
    echo "Skipping file download (db only)."
    exit 0
fi

cnt=0
while read FILE CSIZE; do
    wget_pv $((++cnt)) $NFILES $REPO/$SYS_ARCH/$FILE $MIRROR/$SYS_ARCH $CSIZE
    wget_pv $cnt $NFILES $REPO/$SYS_ARCH/${FILE}.sig $MIRROR/$SYS_ARCH
done < $FILES


