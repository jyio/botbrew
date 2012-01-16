NAME	:= sqlite-amalgamation
VERSION	:= 3070900
ARCHIVE	:= ${NAME}-${VERSION}.zip

# exports

EXPORT_MAKE		+= $~/install $~/package/*.yml
EXPORT_INSTALL	+= $~/install
EXPORT_PACKAGE	+= $~/package/*.yml
EXPORT_CLEAN	+= $~/clean
EXPORT_CLOBBER	+= $~/clobber

# locals

__SQLITE :=	-DHAVE_READLINE=1 \
		-DSQLITE_ENABLE_FTS3 \
		-DSQLITE_ENABLE_FTS3_PARENTHESIS \
		-DSQLITE_ENABLE_FTS4 \
		-DSQLITE_ENABLE_RTREE \
		-DSQLITE_ENABLE_STAT3 \
		-DSQLITE_SOUNDEX

define RECIPE

# common targets

.PHONY: $~/install $~/package/*.yml $~/clean $~/clobber
$~/install: $~/build/.d
	cp -rlf $~/build/* ${TOP_INSTALL}/
$~/package/*.yml: $~/build/.d
	cd ${DIR_REPO}; cat ${TOP}/$$@ | opkg-buildyaml ${TOP}/$~/build
$~/clean:
	rm -f $~/source/*.o
$~/clobber:
	rm -rf $~/source $~/build

# build

$~/${ARCHIVE}:
	rm -rf $$@
	wget http://sqlite.org/${ARCHIVE} -O $$@

$~/source/.d: | $~/${ARCHIVE}
	if [ ! -d $${@D} ]; then \
		unzip $~/${ARCHIVE} -d $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
	fi
	touch $$@

$~/build/.d: $~/source/.d | ${DIR_COOKBOOK}/readline/install
	rm -rf $${@D} $~/source/*.o
	mkdir -p $${@D}/system/bin $${@D}/system/lib $${@D}/system/include
	cd $~/source; agcc.bash -c shell.c sqlite3.c ${CFLAGS} ${__SQLITE}
	${AR} -r $${@D}/system/lib/libsqlite3.a $~/source/sqlite3.o
	agcc.bash -o ${TOP}/$~/build/system/lib/libsqlite3.so -shared -Wl,-soname,libsqlite3.so $~/source/sqlite3.o -ldl
	agcc.bash -o $${@D}/system/bin/sqlite3 $~/source/shell.o ${LDFLAGS} -L$${@D}/system/lib -lreadline -lncurses -lsqlite3
	${STRIP} --strip-unneeded $${@D}/system/bin/* $${@D}/system/lib/*
	cp -rl $~/source/*.h $${@D}/system/include/
	touch $$@

endef

$(eval ${RECIPE})
