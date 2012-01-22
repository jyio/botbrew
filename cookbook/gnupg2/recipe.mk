NAME	:= gnupg
VERSION	:= 2.0.18
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

$~/source/Makefile: | $~/${ARCHIVE} $(call COOK,libgpg-error) $(call COOK,libgcrypt) $(call COOK,libassuan) $(call COOK,libksba) $(call COOK,pth) $(call COOK,libiconv) $(call COOK,readline) $(call COOK,bzip2)
	if [ ! -d $${@D} ]; then \
		tar jxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cp -lf $${@D}/common/util.h $${@D}/g10/; \
		cp -lf $${@D}/common/util.h $${@D}/keyserver/; \
		cp -lf $${@D}/common/util.h $${@D}/tools/; \
		cd  $${@D}; \
			patch -p0 < ../patch/gnupg-2.0.18-android.patch; \
	fi
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" LIBS="-lncurses" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-linux-androideabi \
		--with-gpg-error-prefix=${TOP_INSTALL}/system \
		--with-libgcrypt-prefix=${TOP_INSTALL}/system \
		--with-libassuan-prefix=${TOP_INSTALL}/system \
		--with-ksba-prefix=${TOP_INSTALL}/system \
		--with-pth-prefix=${TOP_INSTALL}/system \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	touch $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	-${STRIP} --strip-unneeded ${TOP}/$~/build/system/bin/* ${TOP}/$~/build/system/libexec/*
	for file in \
		$${@D}/system/bin/gpgsm-gencert.sh \
		$${@D}/system/share/doc/gnupg/examples/scd-event \
		$${@D}/system/xbin/*; do \
			sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $$$${file} > temp; \
			mv temp $$$${file}; \
	done
	touch $$@

endef

$(eval ${RECIPE})
