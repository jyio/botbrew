NAME	:= bzip2
VERSION	:= 1.0.6
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
	wget http://bzip.org/1.0.6/${ARCHIVE} -O $$@

$~/source/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	touch $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source CC="agcc.bash" CFLAGS="${CFLAGS}" AR="${AR}" RANLIB="${RANLIB}" libbz2.a bzip2 bzip2recover
	${MAKE} -C $~/source PREFIX=${TOP}/$~/build install
	mkdir -p $${@D}/system/share
	mv $${@D}/bin $${@D}/include $${@D}/lib $${@D}/system/
	mv $${@D}/man $${@D}/system/share/
	touch $$@

endef

$(eval ${RECIPE})
