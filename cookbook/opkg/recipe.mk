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

$~/source/Makefile: $~/source/configure | $(call COOK,curl) $(call COOK,openssl)
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS} -I${TOP}/$~/compat" LD="agcc.bash" LDFLAGS="${LDFLAGS}" OBJDUMP="${OBJDUMP}" AR="${AR}" STRIP="${STRIP} --strip-unneeded" RANLIB="${RANLIB}" CURL_CFLAGS="-I${TOP_INSTALL}/system/include" CURL_LIBS="-L${TOP_INSTALL}/system/lib" ./configure --host=arm-linux-androideabi --with-opkglibdir=/system/usr/lib --with-opkgetcdir=/system/etc --with-opkglockfile=/cache/opkg/lock --enable-static --disable-shared --enable-openssl=yes --disable-gpg \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	touch $$@

$~/compat/libcompat.a:
	cd $${@D}; rm -f *.o *.a; \
		agcc.bash -c glob.c regexec.c regcomp.c regerror.c regfree.c -I.; \
		${AR} -r libcompat.a *.o

$~/build/.d: $~/source/Makefile $~/compat/libcompat.a
	${MAKE} -C $~/source LIBS="-L${TOP}/$~/compat ${TOP_INSTALL}/system/lib/libcurl.a ${TOP_INSTALL}/system/lib/libssl.a ${TOP_INSTALL}/system/lib/libcrypto.a -lcompat -lz"
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	mkdir -p $${@D}/system
	mv $${@D}/system/bin/opkg-cl $${@D}/system/bin/opkg
	${STRIP} --strip-unneeded $${@D}/system/bin/opkg
	rm -rf $${@D}/system/lib/*.la $${@D}/system/lib/pkgconfig
	for file in \
		$${@D}/system/bin/opkg-key \
		$${@D}/system/bin/update-alternatives \
		$${@D}/system/share/opkg/intercept/*; do \
			sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $$$${file} > temp; \
			cat temp > $$$${file}; \
	done
	rm temp
	touch $$@

endef

$(eval ${RECIPE})
