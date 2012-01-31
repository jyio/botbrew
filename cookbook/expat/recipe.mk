NAME	:= expat
VERSION	:= 2.0.1
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
	wget http://downloads.sourceforge.net/project/${NAME}/${NAME}/${VERSION}/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi

$~/source/Makefile: $~/source/configure
	cd $${@D}; CC="agcc.bash" LD="agcc.bash" AR="${AR}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include \
		--infodir=/system/share/info \
		--mandir=/system/share/man

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm $${@D}/system/lib/*.la
	${STRIP} --strip-unneeded $${@D}/system/bin/*
	touch $$@

endef

$(eval ${RECIPE})
