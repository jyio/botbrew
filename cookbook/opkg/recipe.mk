NAME	:= opkg
VERSION	:= 0.1.8
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
	rm $~/compat/*.o $~/compat/*.a
$~/clobber:
	rm -rf $~/source $~/build $~/compat/*.o $~/compat/*.a

# build

$~/source/configure:
	if [ ! -d $${@D} ]; then \
		svn checkout http://opkg.googlecode.com/svn/trunk/ $${@D}; \
		cd $${@D}; patch -p0 < ../patch/opkg-0.1.8-android.patch; \
	fi
	cd $${@D}; \
		autoreconf -v --install; \
		glib-gettextize --force --copy
	touch $$@

$~/source/Makefile: $~/source/configure | ${DIR_COOKBOOK}/curl/install ${DIR_COOKBOOK}/openssl/install
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS} -I${TOP}/$~/compat" LD="agcc.bash" LDFLAGS="${LDFLAGS}" OBJDUMP="${OBJDUMP}" AR="${AR}" STRIP="${STRIP} --strip-unneeded" RANLIB="${RANLIB}" CURL_CFLAGS="-I${TOP_INSTALL}/system/include" CURL_LIBS="-L${TOP_INSTALL}/system/lib" ./configure --host=arm-eabi --with-opkglibdir=/system/usr/lib --with-opkgetcdir=/system/etc --disable-shared --enable-static --enable-openssl=yes --enable-gpg=no \
		--prefix=${TOP}/$~/build/system \
		--sbindir=${TOP}/$~/build/system/xbin \
		--sharedstatedir=${TOP}/$~/build/data/local/com \
		--localstatedir=${TOP}/$~/build/data/local/var \
		--oldincludedir=${TOP}/$~/build/system/include
	touch $$@

$~/compat/libcompat.a:
	cd $${@D}; rm -f *.o *.a; \
		agcc.bash -c glob.c regexec.c regcomp.c regerror.c regfree.c -I.; \
		${AR} -r libcompat.a *.o

$~/build/.d: $~/source/Makefile $~/compat/libcompat.a
	${MAKE} -C $~/source LIBS="-L${TOP}/$~/compat -lcompat -lcurl -lssl -lcrypto -lz"
	${MAKE} -C $~/source install
	mkdir -p $${@D}/system
	mv $${@D}/system/bin/opkg-cl $${@D}/system/bin/opkg
	rm -rf $${@D}/system/lib/*.la $${@D}/system/lib/pkgconfig
	for file in \
		$${@D}/system/bin/opkg-key \
		$${@D}/system/bin/update-alternatives \
		$${@D}/system/share/opkg/intercept/*; do \
			sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $$$${file} > temp; \
			mv temp $$$${file}; \
	done
	touch $$@

endef

$(eval ${RECIPE})
