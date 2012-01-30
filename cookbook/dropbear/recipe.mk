NAME	:= dropbear
VERSION	:= 2011.54
ARCHIVE	:= ${NAME}-${VERSION}.tar.gz

# exports

EXPORT_MAKE		+= $~/install $~/package/*.yml
EXPORT_INSTALL	+= $~/install
EXPORT_PACKAGE	+= $~/package/*.yml
EXPORT_CLEAN	+= $~/clean
EXPORT_CLOBBER	+= $~/clobber

# locals

__PROGRAMS	:= dropbear dbclient dropbearkey dropbearconvert scp

define RECIPE

# common targets

.PHONY: $~/install $~/package/*.yml $~/clean $~/clobber
$~/install: $~/build/.d
	cp -rlf $~/build/* ${TOP_INSTALL}/
$~/package/*.yml: $~/build/.d
	cd ${DIR_REPO}; cat ${TOP}/$$@ | opkg-buildyaml ${TOP}/$~/build
$~/clean:
	${MAKE} -C $~/source clean
$~/clobber:
	rm -rf $~/source $~/build

# build

$~/${ARCHIVE}:
	rm -rf $$@
	wget http://matt.ucc.asn.au/dropbear/releases/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cp $~/patch/netbsd_getpass.c $${@D}/; \
		cd $${@D}; \
			patch -p0 < ../patch/dropbear-2011.54-android.patch; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" LD="agcc.bash" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--disable-loginfunc \
		--disable-shadow \
		--disable-utmp \
		--disable-utmpx \
		--disable-wtmp \
		--disable-wtmpx \
		--disable-pututline \
		--disable-pututxline \
		--disable-lastlog \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source PROGRAMS="${__PROGRAMS}" SCPPROGRESS=1
	${MAKE} -C $~/source install PROGRAMS="${__PROGRAMS}" DESTDIR=${TOP}/$~/build
	mv $~/build/system/sbin/* $~/build/system/bin/
	rm -rf $~/build/system/sbin
	touch $$@

endef

$(eval ${RECIPE})
