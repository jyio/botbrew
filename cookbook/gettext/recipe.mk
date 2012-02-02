NAME	:= gettext
VERSION	:= 0.18.1.1
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
	wget http://ftp.gnu.org/gnu/${NAME}/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE} ${DIR_COOKBOOK}/pth/install ${DIR_COOKBOOK}/libiconv/install ${DIR_COOKBOOK}/libunistring/install ${DIR_COOKBOOK}/ncurses/install ${DIR_COOKBOOK}/expat/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; \
			patch -p0 < ../patch/gettext-0.18.1.1-android.patch; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" LD="agcc.bash" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--with-libpth-prefix=${TOP_INSTALL}/system \
		--with-libiconv-prefix=${TOP_INSTALL}/system \
		--with-included-glib \
		--with-included-libcroco \
		--with-libunistring-prefix=${TOP_INSTALL}/system \
		--with-included-libxml \
		--with-libncurses-prefix=${TOP_INSTALL}/system \
		--with-libexpat-prefix=${TOP_INSTALL}/system \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	$(call GNULIB,$${@D}/gettext-runtime/gnulib-lib)
	$(call GNULIB,$${@D}/gettext-runtime/libasprintf)
	$(call GNULIB,$${@D}/gettext-tools/gnulib-lib)
	$(call GNULIB,$${@D}/gettext-tools/libgettextpo)
	$(call GNULIB,$${@D}/gettext-tools/libgrep)

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm $${@D}/system/lib/*.la $${@D}/system/lib/charset.alias
	-${STRIP} --strip-unneeded $${@D}/system/bin/* $${@D}/system/lib/gettext/*
	for file in `grep -rlIF '/bin/sh' $${@D}`; do \
		sed -e 's/\/bin\/sh/\/system\/bin\/sh/' $$$${file} > temp; \
		cat temp > $$$${file}; \
	done
	rm temp
	touch $$@

endef

$(eval ${RECIPE})
