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

__CFLAGS	:= ${CFLAGS} -I${TOP}/$~/source/jni/libcrypt -I${TOP}/$~/source/jni/sqlite3
__LDFLAGS	:= ${LDFLAGS} -L${TOP}/$~ -L${TOP}/$~/source
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

$~/libs: | $~/jni
	cd $${@D}; ndk-build

# host tools

$~/source-host/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	cd $${@D}; ./configure --prefix=${TOP}/$~/build-host
	touch $$@

$~/build-host/.d: $~/source-host/Makefile
	${MAKE} -C $~/source-host
	${MAKE} -C $~/source-host install
	cp -lf $~/source-host/Parser/pgen $~/build-host/bin/
	cd $${@D}; \
		curl http://python-distribute.org/distribute_setup.py | ${__HPYTHON}; \
		curl https://raw.github.com/pypa/pip/master/contrib/get-pip.py | ${__HPYTHON}; \
		./bin/pip install virtualenv; \
		./bin/pip install virtualenvwrapper
	touch $$@

# target

# depend on source-host to prevent race condition
$~/source/Makefile: | $~/${ARCHIVE} $~/source-host/Makefile ${DIR_COOKBOOK}/readline/install ${DIR_COOKBOOK}/bzip2/install ${DIR_COOKBOOK}/openssl/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; \
			patch -p1 < ../patch/Python-2.7.2-xcompile.patch; \
			patch -p1 < ../patch/Python-2.7.2-android.patch; \
			patch -p0 < ../patch/Python-2.7.2-regen.patch; \
	fi
	cd $${@D}; CC="agcc.bash" CFLAGS="${__CFLAGS}" LD="agcc.bash" LDFLAGS="${__LDFLAGS} -ldl" ./configure --host=arm-eabi --enable-shared \
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
	touch $$@

$~/build/.d: $~/source/Makefile | $~/libs $~/build-host/.d
	${MAKE} -C $~/source BLDSHARED="agcc.bash -shared ${__CFLAGS} ${__LDFLAGS} -ldl -lbz2 -lreadline -lncurses" HOSTPYTHON="${__HPYTHON}" HOSTPGEN="${__HPGEN}" CROSS_COMPILE=arm-eabi CROSS_COMPILE_TARGET=yes HOSTARCH=arm-linux INSTSONAME=libpython2.7.so libpython2.7.so
	ARCH="armeabi" NDKPLATFORM="${NDKPLATFORM}" ${MAKE} -C $~/source BLDSHARED="agcc.bash -shared ${__CFLAGS} ${__LDFLAGS} -ldl -lpython2.7" HOSTPYTHON="${__HPYTHON}" HOSTPGEN="${__HPGEN}" CROSS_COMPILE=arm-eabi CROSS_COMPILE_TARGET=yes HOSTARCH=arm-linux INSTSONAME=libpython2.7.so
	ARCH="armeabi" NDKPLATFORM="${NDKPLATFORM}" ${MAKE} -C $~/source install HOSTPYTHON="${__HPYTHON}" CROSS_COMPILE=arm-eabi CROSS_COMPILE_TARGET=yes DESTDIR=${TOP}/$~/build
	touch $$@

endef

$(eval ${RECIPE})
