NAME	:= gpgme
VERSION	:= 1.3.1
ARCHIVE	:= ${NAME}-${VERSION}.tar.bz2

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
	wget ftp://ftp.gnupg.org/gcrypt/${NAME}/${ARCHIVE} -O $$@

$~/source/Makefile: | $~/${ARCHIVE} $(call COOK,libgpg-error) $(call COOK,libassuan) $(call COOK,pth)
	if [ ! -d $${@D} ]; then \
		tar jxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--with-gpg-error-prefix=${TOP_INSTALL}/system \
		--with-libassuan-prefix=${TOP_INSTALL}/system \
		--with-pth=yes \
		--with-gpg=/system/bin/gpg2 \
		--with-gpgsm=/system/bin/gpgsm \
		--with-gpgconf=/system/bin/gpgconf \
		--with-g13=/system/bin/g13 \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	touch $$@

$~/build/.d: $~/source/Makefile
	rm ${TOP_INSTALL}/system/lib/*.la
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $${@D}/system/bin/gpgme-config > temp
	mv temp $${@D}/system/bin/gpgme-config
	touch $$@

endef

$(eval ${RECIPE})
