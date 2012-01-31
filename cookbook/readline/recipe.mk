NAME	:= readline
VERSION	:= 6.2
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

$~/source/Makefile: | $~/${ARCHIVE} ${DIR_COOKBOOK}/ncurses/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; patch -p0 < ../patch/readline-6.2-android.patch; \
	fi
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" LIBS="${TOP_INSTALL}/system/lib/libncurses.a" STRIP="${STRIP} --strip-unneeded" RANLIB="${RANLIB}" ./configure --host=arm-android-eabi \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	sed -e 's/^SHLIB_LIBVERSION = .*/SHLIB_LIBVERSION = so/g' $${@D}/shlib/Makefile > temp
	mv temp $${@D}/shlib/Makefile

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -f $${@D}/system/lib/*.old
	agcc.bash -shared -Wl,-soname,libreadline.so -o $${@D}/system/lib/libreadline.libncurses.so \
		$${@D}/system/lib/libreadline.a \
		${TOP_INSTALL}/system/lib/libncurses.a
	mv $${@D}/system/lib/libreadline.libncurses.so $${@D}/system/lib/libreadline.so
	${STRIP} --strip-unneeded $${@D}/system/lib/*.so
	touch $$@

endef

$(eval ${RECIPE})
