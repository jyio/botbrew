NAME	:= Python
VERSION	:= 2.7.2
ARCHIVE	:= ${NAME}-${VERSION}.tgz

# exports

EXPORT_MAKE		+= $~/install $~/package/*.yml
EXPORT_INSTALL	+= $~/install
EXPORT_PACKAGE	+= $~/package/*.yml
EXPORT_CLEAN	+= $~/clean
EXPORT_CLOBBER	+= $~/clobber

# locals

__CFLAGS	:= ${CFLAGS}
__LDFLAGS	:= ${LDFLAGS} -L${TOP}/$~/source
__HPYTHON	:= ${TOP}/$~/build-host/bin/python
__HPGEN		:= ${TOP}/$~/build-host/bin/pgen

define RECIPE

# common targets

.PHONY: $~/install $~/package/*.yml $~/clean $~/clobber
$~/install: $~/build/.d
	cp -rlf $~/build/* ${TOP_INSTALL}/
$~/package/*.yml: $~/build/.d
	cd ${DIR_REPO}; cat ${TOP}/$$@ | opkg-buildyaml ${TOP}/$~/build
$~/clean:
	${MAKE} -C $~/source clean
	${MAKE} -C $~/source-host clean
	rm -rf $~/libs $~/obj
$~/clobber:
	rm -rf $~/source* $~/build* $~/libs $~/obj

# build

$~/${ARCHIVE}:
	rm -rf $$@
	wget http://www.python.org/ftp/python/${VERSION}/${ARCHIVE} -O $$@

# JNI
#$~/libs: | $~/jni
#	cd $${@D}; ndk-build

# host tools

$~/source-host/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	cd $${@D}; ./configure --prefix=${TOP}/$~/build-host
	touch $$@

$~/build-host/.d: $~/source-host/Makefile
	${MAKE} -C $~/source-host python Parser/pgen
	${MAKE} -C $~/source-host install
	cp -lf $~/source-host/Parser/pgen $~/build-host/bin/
	#cd $${@D}; \
	#	curl http://python-distribute.org/distribute_setup.py | ${__HPYTHON}; \
	#	curl https://raw.github.com/pypa/pip/master/contrib/get-pip.py | ${__HPYTHON}; \
	#	./bin/pip install virtualenv; \
	#	./bin/pip install virtualenvwrapper
	touch $$@

# target

# depend on source-host to prevent race condition
$~/source/Makefile: | $~/${ARCHIVE} $~/source-host/Makefile ${DIR_COOKBOOK}/readline/install ${DIR_COOKBOOK}/sqlite3/install ${DIR_COOKBOOK}/bzip2/install ${DIR_COOKBOOK}/openssl/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; \
			patch -p1 < ../patch/Python-2.7.2-xcompile.patch; \
			patch -p1 < ../patch/Python-2.7.2-android.patch; \
			patch -p0 < ../patch/Python-2.7.2-regen.patch; \
	fi
	cd $${@D}; CC="agcc.bash ${__CFLAGS}" LD="agcc.bash" LDFLAGS="${__LDFLAGS}" AR="${AR}" RANLIB="${RANLIB}" ./configure --build=i686 --host=arm-linux-androideabi --enable-shared --with-readline=${TOP_INSTALL}/system/lib INSTSONAME=libpython2.7.so \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	cat $${@D}/pyconfig.h \
		| sed -e '/HAVE_FDATASYNC/ c#undef HAVE_FDATASYNC' \
		| sed -e '/HAVE_KILLPG/ c#undef HAVE_KILLPG' \
		| sed -e '/HAVE_GETHOSTBYNAME_R/ c#undef HAVE_GETHOSTBYNAME_R' \
		| sed -e '/HAVE_DECL_ISFINITE/ c#undef HAVE_DECL_ISFINITE' \
		> temp
	mv temp $${@D}/pyconfig.h
	cat $${@D}/setup.py \
		| sed -e 's/\/usr\/include/\/system\/include/g' \
		| sed -e 's/\/usr\/lib/\/system\/lib/g' \
		| sed -e 's/\/usr\/local/\/system/g' \
		> temp
	mv temp $${@D}/setup.py
	touch $$@

$~/build/.d: $~/source/Makefile | $~/build-host/.d
	ARCH="armeabi" NDKPLATFORM="${NDKPLATFORM}" ${MAKE} -C $~/source LDFLAGS="${__LDFLAGS} -ldl -lncurses -lhistory -lcrypto -lssl" HOSTPYTHON="${__HPYTHON}" HOSTPGEN="${__HPGEN}" CROSS_COMPILE_TARGET=yes libpython2.7.so
	ARCH="armeabi" NDKPLATFORM="${NDKPLATFORM}" ${MAKE} -C $~/source LDFLAGS="${__LDFLAGS} -ldl -lpython2.7" HOSTPYTHON="${__HPYTHON}" HOSTPGEN="${__HPGEN}" CROSS_COMPILE_TARGET=yes
	ARCH="armeabi" NDKPLATFORM="${NDKPLATFORM}" ${MAKE} -C $~/source install HOSTPYTHON="${__HPYTHON}" CROSS_COMPILE_TARGET=yes DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/pkgconfig
	touch $$@

endef

$(eval ${RECIPE})
