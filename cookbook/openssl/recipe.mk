NAME	:= openssl
VERSION	:= 1.0.0f
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
	wget http://www.openssl.org/source/${ARCHIVE} -O $$@

$~/source/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" RANLIB="${RANLIB}" STRIP="${STRIP} --strip-unneeded" ./Configure linux-generic32 no-asm no-idea no-bf no-cast no-seed no-md2 -DL_ENDIAN --prefix=/system --openssldir=/system/etc/ssl
	touch $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source depend MAKEDEPPROG="agcc.bash -E -MM"
	${MAKE} -C $~/source
	${MAKE} -C $~/source install INSTALL_PREFIX=${TOP}/$~/build
	mkdir -p $${@D}/system/share
	mv $${@D}/system/etc/ssl/man $${@D}/system/share/
	mv $${@D}/system/etc/ssl/openssl.cnf $${@D}/system/etc/ssl/openssl.cnf.opkg-new
	chmod -R 0710 $${@D}/system/etc/ssl/private
	rm -rf $${@D}/system/lib/pkgconfig
	touch $$@

endef

$(eval ${RECIPE})
