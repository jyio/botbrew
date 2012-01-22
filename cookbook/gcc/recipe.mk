NAME	:= gcc
VERSION	:= 4.6.2
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
	${MAKE} -C $~/object clean
$~/clobber:
	rm -rf $~/source $~/object $~/build

# build

$~/${ARCHIVE}:
	rm -rf $$@
	wget http://ftp.gnu.org/gnu/${NAME}/${NAME}-${VERSION}/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE} ${DIR_COOKBOOK}/binutils/install ${DIR_COOKBOOK}/gmp/install ${DIR_COOKBOOK}/mpfr/install ${DIR_COOKBOOK}/mpc/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cp -lf $${@D}/include/sha1.h $${@D}/libiberty/; \
		cd $${@D}; \
			patch -p0 < ../patch/gcc-4.6.2-android.patch; \
	fi

# --disable-symvers to suppress "version node not found for symbol"
$~/object/Makefile: $~/source/configure
	mkdir -p $${@D}
	cd $${@D}; \
		CC="agcc.bash" LD="agcc.bash" AR="${AR}" STRIP="${STRIP} --strip-unneeded" target_configargs="--disable-symvers" ${TOP}/$~/source/configure --host=arm-linux-androideabi --target=arm-linux-androideabi --disable-bootstrap --enable-languages=c,lto --disable-nls --with-gmp=${TOP_INSTALL}/system --with-mpfr=${TOP_INSTALL}/system --with-mpc=${TOP_INSTALL}/system \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include

$~/build/.d: $~/object/Makefile
	${MAKE} -C $~/object CC_FOR_TARGET="agcc.bash"
	${MAKE} -C $~/object install DESTDIR=${TOP}/$~/build
	cp -rlf ${AGCC_NDK}/platforms/android-${AGCC_API}/arch-arm/usr/include $${@D}/system/
	cp -rlf ${AGCC_NDK}/platforms/android-${AGCC_API}/arch-arm/usr/lib/*.a $${@D}/system/lib/
	cp -rlf ${AGCC_NDK}/platforms/android-${AGCC_API}/arch-arm/usr/lib/crt*.o $${@D}/system/lib/gcc/arm-linux-androideabi/${VERSION}/
	cp -rlf $${@D}/system/lib/gcc/arm-linux-androideabi/4.4.3/* $${@D}/system/lib/gcc/arm-linux-androideabi/${VERSION}/
	rm -f $${@D}/system/bin/arm-linux-androideabi-*

	touch $$@

endef

$(eval ${RECIPE})
