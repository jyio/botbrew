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
	cat $${@D}/Makefile-libbz2_so \
		| sed -e 's/\blibbz2\.so[0123456789\.]*/libbz2.so/g' $${@D}/Makefile-libbz2_so \
		| sed -e 's/rm \-f libbz2\.so//g' \
		| sed -e 's/ln \-s libbz2\.so libbz2\.so//g' \
		> temp
	mv temp $${@D}/Makefile-libbz2_so

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source CC="agcc.bash" CFLAGS="${CFLAGS}" AR="${AR}" RANLIB="${RANLIB}" PREFIX=${TOP}/$~/build install
	${MAKE} -f Makefile-libbz2_so -C $~/source CC="agcc.bash" CFLAGS="${CFLAGS}" AR="${AR}" RANLIB="${RANLIB}" all
	cp -lf $~/source/bzip2-shared $~/build/bin/
	cp -lf $~/source/libbz2.so $~/build/lib/
	mkdir -p $${@D}/system/share
	mv $${@D}/bin $${@D}/include $${@D}/lib $${@D}/system/
	mv $${@D}/man $${@D}/system/share/
	for file in \
		$${@D}/system/bin/bzdiff \
		$${@D}/system/bin/bzgrep \
		$${@D}/system/bin/bzmore; do \
			sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $$$${file} > temp; \
			cat temp > $$$${file}; \
	done
	rm temp
	cd $${@D}/system/bin; \
		ln -sf bzdiff bzcmp; \
		ln -sf bzgrep bzegrep; \
		ln -sf bzgrep bzfgrep; \
		ln -sf bzmore bzless;
	cd $${@D}/system/bin; \
		${STRIP} --strip-unneeded bunzip2 bzcat bzip2 bzip2recover bzip2-shared
	${STRIP} --strip-unneeded $${@D}/system/lib/libbz2.so
	touch $$@

endef

$(eval ${RECIPE})
