NAME	:= ncurses
VERSION	:= 5.9
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

# nb: Android's broken locale implementation results in errors such as
#     'struct lconv' has no member named 'decimal_point'
# fix: undefine HAVE_LOCALE_H in include/ncurses_cfg.h
$~/source/Makefile: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	cat $${@D}/configure \
		| sed -E 's/\.\$$$$[\{\(](ABI|REL)_VERSION[\)\}]//g' \
		> temp
	cat temp > $${@D}/configure
	cat $${@D}/mk-1st.awk \
		| sed -E 's/\.\$$$$[\{\(](ABI|REL)_VERSION[\)\}]//g' \
		> temp
	mv temp $${@D}/mk-1st.awk
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" CXX="agcc.bash" CXXFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-linux-androideabi --with-shared --without-cxx-binding \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include \
		--infodir=/system/share/info \
		--mandir=/system/share/man
	sed -e 's/#define HAVE_LOCALE_H 1//' $${@D}/include/ncurses_cfg.h > temp
	mv temp $${@D}/include/ncurses_cfg.h
	sed -E 's/\(\)/:/g' $${@D}/ncurses/Makefile > temp
	mv temp $${@D}/ncurses/Makefile
	sed -E 's/\(\)/:/g' $${@D}/form/Makefile > temp
	mv temp $${@D}/form/Makefile
	sed -E 's/\(\)/:/g' $${@D}/menu/Makefile > temp
	mv temp $${@D}/menu/Makefile
	sed -E 's/\(\)/:/g' $${@D}/panel/Makefile > temp
	mv temp $${@D}/panel/Makefile

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	mv $${@D}/system/include/ncurses/* $${@D}/system/include/
	rm -rf $${@D}/system/include/ncurses
	for file in $${@D}/system/include/*.h; do \
		sed -e 's/<ncurses\//</g' $$$${file} > temp; \
		mv temp $$$${file}; \
	done
	touch $$@

endef

$(eval ${RECIPE})
