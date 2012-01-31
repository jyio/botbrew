NAME	:= nettle
VERSION	:= 2.4
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
	wget http://www.lysator.liu.se/~nisse/archive/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" CXX="agcc-bash-g++" CXXFLAGS="-I${NDKPATH}/sources/cxx-stl/stlport/stlport -Duint64_t='unsigned long long'" LD="agcc.bash" LIBS="${NDKPATH}/sources/cxx-stl/stlport/libs/armeabi/libstlport_static.a" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi --enable-shared \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	sed -E 's/^LIBNETTLE_(SONAME|FILE) = .*/LIBNETTLE_\1 = libnettle.so/g' $${@D}/config.make > temp
	mv temp $${@D}/config.make
	cat $${@D}/Makefile \
		| sed -e 's/ln -sf \S* \S*/true/g' \
		| sed -E 's/\(cd (\S*) \\/cd \1 \\/g' \
		> temp
	mv temp $${@D}/Makefile

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/pkgconfig
	${STRIP} --strip-unneeded $${@D}/system/bin/* $${@D}/system/lib/*.so
	touch $$@

endef

$(eval ${RECIPE})
