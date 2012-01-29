NAME	:= runit
VERSION	:= 2.1.1
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
	${MAKE} -C $~/source/src clean
$~/clobber:
	rm -rf $~/source $~/build

# build

$~/${ARCHIVE}:
	rm -rf $$@
	wget http://smarden.org/${NAME}/${ARCHIVE} -O $$@

$~/source/src/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/admin/${NAME}-${VERSION} $~/source; \
		rm -rf $~/admin; \
	fi
	cd $${@D}; \
		patch -p0 < ../../patch/runit-2.1.1-android.patch
	echo "agcc.bash" > $${@D}/conf-cc
	echo "agcc.bash -s" > $${@D}/conf-ld
	${MAKE} -C $${@D} compile load choose
	cp $${@D}/iopause.h2	$${@D}/iopause.h
	cp $${@D}/uint64.h2	$${@D}/uint64.h
	${MAKE} -C $${@D} chkshsgr
	cp $${@D}/hasshsgr.h2	$${@D}/hasshsgr.h
	sed -e 's/static/shared/g' $$@ > temp
	mv temp $$@

$~/build/.d: $~/source/src/Makefile
	${MAKE} -C $~/source/src
	mkdir -p $${@D}/system/bin $${@D}/system/xbin $${@D}/system/share/man $${@D}/system/share/doc
	cp -lf $~/source/src/chpst	$${@D}/system/bin
	cp -lf $~/source/src/runit	$${@D}/system/xbin
	cp -lf $~/source/src/runit-init	$${@D}/system/xbin
	cp -lf $~/source/src/runsv	$${@D}/system/bin
	cp -lf $~/source/src/runsvchdir	$${@D}/system/bin
	cp -lf $~/source/src/runsvdir	$${@D}/system/bin
	cp -lf $~/source/src/sv		$${@D}/system/bin
	cp -lf $~/source/src/svlogd	$${@D}/system/bin
	cp -lf $~/source/src/utmpset	$${@D}/system/bin
	cp -rlf $~/source/man $${@D}/system/share/man/man8
	cp -rlf $~/source/doc $${@D}/system/share/doc/runit
	touch $$@

endef

$(eval ${RECIPE})
