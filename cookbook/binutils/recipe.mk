NAME	:= binutils
VERSION	:= 2.22
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
	wget http://ftp.gnu.org/gnu/${NAME}/${ARCHIVE} -O $$@

$~/source/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cp -lf $${@D}/include/sha1.h $${@D}/libiberty/; \
		cp -lf $${@D}/include/sha1.h $${@D}/ld/; \
		cd $${@D}; \
			patch -p0 < ../patch/binutils-2.22-xcompile.patch; \
	fi
	cd $${@D}; CC="agcc.bash" CXX="agcc.bash" LD="agcc-bash-g++" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-linux-androideabi --target=arm-linux-androideabi \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	touch $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	cp -rlf $${@D}/system/arm-linux-androideabi/* $${@D}/system/
	rm -rf $${@D}/system/arm-linux-androideabi $${@D}/system/lib/libiberty.*
	touch $$@

endef

$(eval ${RECIPE})
