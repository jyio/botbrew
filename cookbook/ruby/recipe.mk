NAME	:= ruby
VERSION	:= 1.9.3-p0
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
	wget http://ftp.ruby-lang.org/pub/ruby/1.9/${ARCHIVE} -O $$@

$~/source/Makefile: | $~/${ARCHIVE} ${DIR_COOKBOOK}/readline/install ${DIR_COOKBOOK}/openssl/install
	if [ ! -d $${@D} ]; then \
		tar zxf $~/${ARCHIVE} -C $~/; \
		mv $~/${NAME}-${VERSION} $${@D}; \
		cd $${@D}; patch -p0 < ../patch/ruby-1.9.3-android.patch; \
	fi
	cd $${@D}; CC="agcc.bash" CFLAGS="${CFLAGS}" CXX="agcc.bash" CXXFLAGS="${CFLAGS}" LD="agcc.bash" LDSHARED="agcc.bash -shared -lgcc" LDFLAGS="${LDFLAGS}" STRIP="${STRIP} --strip-unneeded" ./configure --host=arm-android-eabi --enable-shared --disable-ipv6 --disable-wide-getaddrinfo \
		--prefix=/system \
		--sbindir=/system/xbin \
		--sharedstatedir=/data/local/com \
		--localstatedir=/data/local/var \
		--oldincludedir=/system/include
	touch $$@

$~/build/.d: $~/source/Makefile
	${MAKE} -C $~/source
	${MAKE} -C $~/source install DESTDIR=${TOP}/$~/build
	rm -rf $${@D}/system/lib/pkgconfig
	touch $$@

endef

$(eval ${RECIPE})
