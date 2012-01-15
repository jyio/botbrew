UTILS = opkg-build opkg-unbuild opkg-compare-versions opkg-make-index opkg.py \
        opkg-list-fields arfile.py opkg-buildpackage opkg-diff opkg-extract-file opkg-show-deps \
        opkg-compare-indexes opkg-compare-versions.sh

DESTDIR=
PREFIX=/usr/local
bindir=$(PREFIX)/bin

all: opkg-compare-versions

opkg-compare-versions: opkg-compare-versions.c
	$(CC) $(CFLAGS) -o opkg-compare-versions opkg-compare-versions.c

install: opkg-compare-versions
	install -d $(DESTDIR)$(bindir)
	install -m 755 $(UTILS) $(DESTDIR)$(bindir)

clean:
	rm -rf opkg-compare-versions
