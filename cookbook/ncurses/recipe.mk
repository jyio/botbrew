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
$~/install: $~/build/.d $~/buildw/.d
	cp -rlf $~/buildw/* $~/build/* ${TOP_INSTALL}/
$~/package/*.yml: $~/build/.d $~/buildw/.d
	cd ${DIR_REPO}; cat ${TOP}/$$@ | opkg-buildyaml ${TOP}/$~/build
$~/clean:
	${MAKE} -C $~/object clean
	${MAKE} -C $~/objectw clean
$~/clobber:
	rm -rf $~/source $~/object $~/objectw $~/build $~/buildw

# build

$~/${ARCHIVE}:
	rm -rf $$@
	wget http://ftp.gnu.org/gnu/${NAME}/${ARCHIVE} -O $$@

$~/source/configure: | $~/${ARCHIVE}
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

# nb: Android's broken locale implementation results in errors such as
#     'struct lconv' has no member named 'decimal_point'
# fix: undefine HAVE_LOCALE_H in include/ncurses_cfg.h
$~/object/Makefile: $~/source/configure
	mkdir -p $${@D}
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" CXX="agcc.bash" CXXFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" ${TOP}/$~/source/configure --host=arm-linux-androideabi --with-shared --without-cxx-binding \
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
$~/objectw/Makefile: $~/source/configure
	mkdir -p $${@D}
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" CXX="agcc.bash" CXXFLAGS="${CFLAGS}" LD="agcc.bash" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" ${TOP}/$~/source/configure --host=arm-linux-androideabi --enable-widec --with-shared --without-cxx-binding \
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

$~/build/.d: $~/object/Makefile $~/objectw/Makefile
	${MAKE} -C $~/object
	${MAKE} -C $~/object install DESTDIR=${TOP}/$~/build
	sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $${@D}/system/bin/ncurses5-config > temp
	cat temp > $${@D}/system/bin/ncurses5-config
	rm temp
	cd $${@D}/system/bin; \
		${STRIP} --strip-unneeded captoinfo clear infocmp infotocap reset tabs tic toe tput tset
	${STRIP} --strip-unneeded $${@D}/system/lib/*.so
	touch $$@

$~/buildw/.d: $~/object/Makefile $~/objectw/Makefile
	${MAKE} -C $~/objectw
	${MAKE} -C $~/objectw install DESTDIR=${TOP}/$~/buildw
	sed -e 's/#!\/bin\/sh/#!\/system\/bin\/sh/' $${@D}/system/bin/ncursesw5-config > temp
	cat temp > $${@D}/system/bin/ncursesw5-config
	rm temp
	cd $${@D}/system/bin; \
		${STRIP} --strip-unneeded captoinfo clear infocmp infotocap reset tabs tic toe tput tset
	${STRIP} --strip-unneeded $${@D}/system/lib/*.so
	touch $$@

endef

$(eval ${RECIPE})
