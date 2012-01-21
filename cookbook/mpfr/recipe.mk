NAME	:= mpfr
VERSION	:= 3.1.0
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
	wget http://www.mpfr.org/${NAME}-current/${ARCHIVE} -O $$@

$~/source/Makefile: | $~/${ARCHIVE} ${DIR_COOKBOOK}/gmp/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; \
			wget http://www.mpfr.org/${NAME}-current/allpatches -O- \
				| patch -N -Z -p1; \
	fi
	cd $${@D}; CC="agcc.bash" CXX="agcc.bash" LD="agcc-bash-g++" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-linux-androideabi --with-gmp=${TOP_INSTALL}/system \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	sed -e 's/-DHAVE_LOCALE_H=1//' $${@D}/src/Makefile > temp
	mv temp $${@D}/src/Makefile
	sed -e 's/-DHAVE_LOCALE_H=1//' $${@D}/doc/Makefile > temp
	mv temp $${@D}/doc/Makefile
	sed -e 's/-DHAVE_LOCALE_H=1//' $${@D}/tune/Makefile > temp
	mv temp $${@D}/tune/Makefile
	sed -e 's/-DHAVE_LOCALE_H=1//' $$@ > temp
	mv temp $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -f $${@D}/system/lib/*.la
	touch $$@

endef

$(eval ${RECIPE})
