NAME	:= weechat
VERSION	:= 0.3.6
ARCHIVE	:= ${NAME}-${VERSION}.tar.gz

# exports

EXPORT_MAKE		+= $~/install $~/package/*.yml
EXPORT_INSTALL	+= $~/install
EXPORT_PACKAGE	+= $~/package/*.yml
EXPORT_CLEAN	+= $~/clean
EXPORT_CLOBBER	+= $~/clobber

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
	wget http://www.weechat.org/files/src/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE} ${DIR_COOKBOOK}/pth/install ${DIR_COOKBOOK}/libiconv/install ${DIR_COOKBOOK}/ncurses/install ${DIR_COOKBOOK}/gnutls/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; \
			patch -p0 < ../patch/weechat-0.3.6-android.patch; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--with-libpth-prefix=${TOP_INSTALL}/system \
		--with-libiconv-prefix=${TOP_INSTALL}/system \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/weechat/plugins/*.la $${@D}/system/lib/pkgconfig
	${STRIP} --strip-unneeded $${@D}/system/bin/*
	touch $$@

endef

$(eval ${RECIPE})
