#! /bin/bash

# set -x

if [ -z "$1" ]; then
    echo "Usage: mirror.sh <MIRROR_PATH>"
    exit 1
fi

MIRROR=$1

SYS_ARCH=msys/x86_64
DB=msys
# msys.db                                            12-Nov-2019 09:00              195498
# msys.db.sig                                        12-Nov-2019 09:00                 119
# msys.db.tar.gz                                     12-Nov-2019 09:00              195498
# msys.db.tar.gz.old                                 08-Nov-2019 19:43              194544
# msys.db.tar.gz.old.sig                             08-Nov-2019 19:43                 119
# msys.db.tar.gz.sig                                 12-Nov-2019 09:00                 119
# msys.files                                         12-Nov-2019 09:00              994543
# msys.files.sig                                     12-Nov-2019 09:00                 119
# msys.files.tar.gz                                  12-Nov-2019 09:00              994543
# msys.files.tar.gz.old                              08-Nov-2019 19:43              994146
# msys.files.tar.gz.old.sig                          08-Nov-2019 19:43                 119
# msys.files.tar.gz.sig                              12-Nov-2019 09:00                 119

# SYS_ARCH=mingw/x86_64
# DB=mingw64
# # mingw64.db                                         21-Nov-2019 11:31              568746
# # mingw64.db.sig                                     21-Nov-2019 11:31                 119
# # mingw64.db.tar.gz                                  21-Nov-2019 11:31              568746
# # mingw64.db.tar.gz.old                              21-Nov-2019 11:30              568166
# # mingw64.db.tar.gz.old.sig                          21-Nov-2019 11:30                 119
# # mingw64.db.tar.gz.sig                              21-Nov-2019 11:31                 119
# # mingw64.files                                      21-Nov-2019 11:31             3604647
# # mingw64.files.sig                                  21-Nov-2019 11:31                 119
# # mingw64.files.tar.gz                               21-Nov-2019 11:31             3604647
# # mingw64.files.tar.gz.old                           21-Nov-2019 11:30             3603339
# # mingw64.files.tar.gz.old.sig                       21-Nov-2019 11:30                 119
# # mingw64.files.tar.gz.sig                           21-Nov-2019 11:31                 119
# 
# SYS_ARCH=mingw/i686
# DB=mingw32
# # mingw32.db                                         21-Nov-2019 11:36              566559
# # mingw32.db.sig                                     21-Nov-2019 11:36                 119
# # mingw32.db.tar.gz                                  21-Nov-2019 11:36              566559
# # mingw32.db.tar.gz.old                              21-Nov-2019 11:34              565976
# # mingw32.db.tar.gz.old.sig                          21-Nov-2019 11:34                 119
# # mingw32.db.tar.gz.sig                              21-Nov-2019 11:36                 119
# # mingw32.files                                      21-Nov-2019 11:36             3590468
# # mingw32.files.sig                                  21-Nov-2019 11:36                 118
# # mingw32.files.tar.gz                               21-Nov-2019 11:36             3590468
# # mingw32.files.tar.gz.old                           21-Nov-2019 11:35             3589328
# # mingw32.files.tar.gz.old.sig                       21-Nov-2019 11:35                 119
# # mingw32.files.tar.gz.sig                           21-Nov-2019 11:36                 118
# 
# # apr-1.7.0-1-x86_64.pkg.tar.xz                      25-Apr-2019 07:55               90676
# # apr-1.7.0-1-x86_64.pkg.tar.xz.sig                  25-Apr-2019 07:55                 119

REPO=http://repo.msys2.org

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

# wget -c $MIRROR_MSYS/msys.files -P $DST
# rm -rf $DST/msys_files
# mkdir -p $DST/msys_files
# tar xf $DST/msys.files -C $DST/msys_files

# rm -rf $DST/msys_db
# mkdir -p $DST/msys_db
# tar xf $DST/msys.db -C $DST/msys_db
# find $DST/msys_db -name desc |
# while read DESC; do
#     cat $DESC | sed -rn '/%FILENAME|%CSIZE/{N;s/\n/ /;p}' | sed -r '/%FILENAME/{N;s/\n/ /;s/%(FILENAME|CSIZE)% //g}'
# done | sort > $DST/msys_db_files

FILES=/tmp/msys_db_files
tar xf $MIRROR/$SYS_ARCH/msys.db -O | sed -rn '/%FILENAME|%CSIZE/{N;s/\n/ /;p}' | sed -r '/%FILENAME/{N;s/\n/ /;s/%(FILENAME|CSIZE)% //g}' | sort > $FILES

NFILES=$(cat $FILES | wc -l)
CSIZE=$(awk -n '{sum += $2} END {print sum}' $FILES)
echo "Must download $NFILES files (size = $((${CSIZE} / 1024 / 1024))MB) and their signatures."

cnt=0
while read FILE CSIZE; do
    printf "[%03d/%03d] Downloading %s (%d bytes)...\n" $((++cnt)) $NFILES ${FILE} $CSIZE
    if command -v pv > /dev/null -a && [ $CSIZE -gt 1000000 ]; then
        wget -q $REPO/$SYS_ARCH/$FILE -O - | pv -s $CSIZE > $MIRROR/$SYS_ARCH/$FILE
    else
        wget -q $REPO/$SYS_ARCH/$FILE -P $MIRROR/$SYS_ARCH/
    fi
    printf "[%03d/%03d] Downloading %s...\n" $cnt $NFILES ${FILE}.sig
    wget -q $REPO/$SYS_ARCH/${FILE}.sig -P $MIRROR/$SYS_ARCH/
done < $FILES


