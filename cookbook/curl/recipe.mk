NAME	:= curl
VERSION	:= 7.24.0
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

$~/source/configure:
	if [ ! -d $${@D} ]; then \
		git clone git://github.com/bagder/curl.git $${@D}; \
	fi
	cd $${@D}; ./buildconf
	touch $$@

$~/source/Makefile: $~/source/configure | ${DIR_COOKBOOK}/openssl/install
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="${LD}" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-linux-androideabi --enable-shared --enable-threaded-resolver --with-ssl --with-ca-path=/system/etc/ssl/certs \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	touch $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/*.la $${@D}/system/lib/pkgconfig
	rm $${@D}/system/bin/curl-config $${@D}/system/lib/libcurl.so $${@D}/system/lib/libcurl.so.5
	mv $${@D}/system/lib/libcurl.so.5.2.0 $${@D}/system/lib/libcurl.so
	${STRIP} --strip-unneeded $${@D}/system/bin/* $${@D}/system/lib/*.so
	touch $$@

endef

$(eval ${RECIPE})
