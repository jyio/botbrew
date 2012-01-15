NAME	:= vim
VERSION	:= 7.3
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

# configuration variables from
# http://credentiality2.blogspot.com/2010/08/native-vim-for-android.html
$~/source/src/auto/config.mk: | ${DIR_COOKBOOK}/ncurses/install
	if [ ! -d $~/source ]; then \
		hg clone https://vim.googlecode.com/hg/ $~/source; \
	fi
	cd $~/source; CC="agcc.bash" CFLAGS="${CFLAGS}" LD="${LD}" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" \
		vim_cv_toupper_broken=no \
		vim_cv_terminfo=yes \
		vim_cv_tty_group=world \
		vim_cv_getcwd_broken=no \
		vim_cv_stat_ignores_slash=no \
		vim_cv_memmove_handles_overlap=no \
		vim_cv_bcopy_handles_overlap=no \
		vim_cv_memcpy_handles_overlap=no \
		./configure --host=arm-eabi --with-tlib=ncurses --disable-gtktest \
			--prefix=${TOP}/$~/build/system \
			--sbindir=${TOP}/$~/build/system/xbin \
			--sharedstatedir=${TOP}/$~/build/data/local/com \
			--localstatedir=${TOP}/$~/build/data/local/var \
			--oldincludedir=${TOP}/$~/build/system/include
	cat $${@D}/config.h \
		| sed -e 's/#define HAVE_SYSINFO 1//' \
		| sed -e 's/#define HAVE_SYSINFO_MEM_UNIT 1//' \
		> temp
	mv temp $${@D}/config.h
	touch $$@

$~/build/.d: $~/source/src/auto/config.mk
	${MAKE} -C $~/source
	${MAKE} -C $~/source install
	touch $$@

endef

$(eval ${RECIPE})
