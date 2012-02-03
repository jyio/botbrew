NAME	:= libevent
VERSION	:= 2.0.16
ARCHIVE	:= ${NAME}-${VERSION}-stable.tar.gz

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
	wget https://github.com/downloads/${NAME}/${NAME}/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION}-stable $${@D}; \
		cd $${@D}; \
			patch -p0 < ../patch/libevent-2.0.16-stable-android.patch; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" LD="agcc.bash" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	sed -e 's/#define HAVE_TAILQFOREACH 1//' $${@D}/config.h > temp
	mv temp $${@D}/config.h

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/*.la $${@D}/system/lib/pkgconfig
	touch $$@

endef

$(eval ${RECIPE})
