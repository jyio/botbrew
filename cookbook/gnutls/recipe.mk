NAME	:= gnutls
VERSION	:= 3.0.12
ARCHIVE	:= ${NAME}-${VERSION}.tar.xz

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
	wget http://ftp.gnu.org/gnu/${NAME}/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE} ${DIR_COOKBOOK}/nettle/install ${DIR_COOKBOOK}/libtasn1/install ${DIR_COOKBOOK}/libiconv/install
	if [ ! -d $${@D} ]; then \
		tar Jxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" CXX="agcc-bash-g++" CXXFLAGS="-I${NDKPATH}/sources/cxx-stl/stlport/stlport -Duint64_t='unsigned long long'" LD="agcc.bash" LDFLAGS="${LDFLAGS}" LIBS="${NDKPATH}/sources/cxx-stl/stlport/libs/armeabi/libstlport_static.a" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--with-nettle-prefix=${TOP_INSTALL}/system \
		--with-libtasn1-prefix=${TOP_INSTALL}/system \
		--with-libiconv-prefix=${TOP_INSTALL}/system \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	$(call GNULIB,$${@D}/gl)
	sed -E 's/(install-exec-am\:) install-defexecDATA/\1/g' $${@D}/lib/Makefile > temp
	mv temp $${@D}/lib/Makefile
	sed -E 's/(install-exec-am\:) install-defexecDATA/\1/g' $${@D}/extra/Makefile > temp
	mv temp $${@D}/extra/Makefile

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/*.la $${@D}/system/lib/pkgconfig
	-${STRIP} --strip-unneeded $${@D}/system/bin/*
	touch $$@

endef

$(eval ${RECIPE})
