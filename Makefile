RECIPE_FILENAME := recipe.mk

TOP				:= $(shell pwd)
TOP_INSTALL		:= ${TOP}/rootfs
DIR_REPO		:= repo
DIR_COOKBOOK	:= cookbook

export OPKG_MAINTAINER	:= Jiang Yio <inportb@gmail.com>
#export AGCC_ECHO	:= yes
#export AGCC_CRYSTAX	:= yes

CROSS			:= arm-linux-androideabi
NDKPATH			:= ${HOME}/android-ndk-r7
NDKREL			:= 7
NDKAPI			:= 8
NDKGCC			:= 4.4.3

-include config.mk

NDKPLATFORM		:= ${NDKPATH}/platforms/android-${NDKAPI}/arch-arm
NDKTOOLCHAIN	:= ${NDKPATH}/toolchains/${CROSS}-${NDKGCC}
NDKPREBUILT		:= ${NDKTOOLCHAIN}/prebuilt/linux-x86
NDKLDSCRIPTS	:= ${NDKPREBUILT}/${CROSS}/lib/ldscripts
CC				:= ${CROSS}-gcc
CXX				:= ${CROSS}-g++
LD				:= ${CROSS}-ld
AR				:= ${CROSS}-ar
NM				:= ${CROSS}-nm
RANLIB			:= ${CROSS}-ranlib
STRIP			:= ${CROSS}-strip
OBJCOPY			:= ${CROSS}-objcopy
OBJDUMP			:= ${CROSS}-objdump

CFLAGS	:= -I${TOP_INSTALL}/system/include -mandroid -fomit-frame-pointer -DNO_MALLINFO=1
LDFLAGS	:= -Wl,-rpath=/system/lib -L${TOP_INSTALL}/system/lib
export PATH	:= ${TOP}/bin:${TOP}/bin/opkg-utils:${NDKPREBUILT}/bin:${NDKPATH}:${PATH}

export AGCC_NDK		:= ${NDKPATH}
export AGCC_REL		:= ${NDKREL}
export AGCC_CXC		:= ${CROSS}
export AGCC_API		:= ${NDKAPI}
export AGCC_GCC		:= ${NDKGCC}
export OPKG_MAINTAINER

RECIPE_LIST = $(shell find . -name ${RECIPE_FILENAME} | sed 's/\/${RECIPE_FILENAME}//')

define COOK
	${DIR_COOKBOOK}/$1/install
endef

define GNULIB
	if [ -f "$1/stdint.in.h" ]; then \
		${MAKE} -C $1 stdint.in.h; \
		echo '#@INCLUDE_NEXT@ @NEXT_STDINT_H@' > $1/stdint.in.h; \
	fi
	if [ -f "$1/time.in.h" ]; then \
		mkdir -p "$1/sys" "$1/asm"; \
		echo '#include <time.h>' > "$1/sys/types.h"; \
		echo '#include_next <sys/types.h>' >> "$1/sys/types.h"; \
		echo '#include <sys/types.h>' > "$1/asm/siginfo.h"; \
		echo '#include_next <asm/siginfo.h>' >> "$1/asm/siginfo.h"; \
	fi
	if [ -f "$1/nl_langinfo.c" ]; then \
		cat $1/nl_langinfo.c \
			| sed -E 's/localeconv \(\) ->decimal_point/","/g' \
			| sed -E 's/localeconv \(\) ->thousands_sep/","/g' \
			> temp; \
		mv temp $1/nl_langinfo.c; \
	fi

endef

define process_recipe
	~				:= $1
	~F				:= ${TOP}/$1
	EXPORT_MAKE		:=
	EXPORT_INSTALL	:=
	EXPORT_PACKAGE	:=
	EXPORT_CLEAN	:=
	EXPORT_CLOBBER	:=
	include			$1/${RECIPE_FILENAME}
	ALL_MAKE		+= $${EXPORT_MAKE}
	ALL_INSTALL		+= $${EXPORT_INSTALL}
	ALL_PACKAGE		+= $${EXPORT_PACKAGE}
	ALL_CLEAN		+= $${EXPORT_CLEAN}
	ALL_CLOBBER		+= $${EXPORT_CLOBBER}

	# The last line of the function must be left blank
	# in order to avoid some quirky, broken gmake
	# behavior when expanding macros within foreach
	# loops.

endef

define process_recipes
	$(foreach DIR,$(RECIPE_LIST),$(call process_recipe,$(DIR)))
endef

# top-level rule, registered before Makefile fragments
.PHONY:	top
top: 	all

CWD			:=
ALL_MAKE	:=
ALL_INSTALL	:=
ALL_PACKAGE	:=
ALL_CLEAN	:=
ALL_CLOBBER	:=

$(eval $(process_recipes))

~			:= tilde is broken in commands

.PHONY:		all package repo clean clobber
all:		$(ALL_MAKE)
install:	$(ALL_INSTALL)
package:	$(ALL_PACKAGE)
	opkg-make-index ${DIR_REPO} > ${DIR_REPO}/Packages
	mv Packages.* ${DIR_REPO}/
	gzip -c9 ${DIR_REPO}/Packages > ${DIR_REPO}/Packages.gz
repo:
	opkg-make-index ${DIR_REPO} > ${DIR_REPO}/Packages
	mv Packages.* ${DIR_REPO}/
	gzip -c9 ${DIR_REPO}/Packages > ${DIR_REPO}/Packages.gz
clean:		$(ALL_CLEAN)
clobber:	$(ALL_CLOBBER)

opkg: opkg.tgz
opkg.tgz: cookbook/opkg/package/opkg.yml
	rm -rf opkg_tgz
	mkdir -p opkg_tgz/CONTROL
	cd opkg_tgz; \
		for opk in ../repo/opkg_*.opk; do :; done; \
		ar x ../repo/$$opk; \
		tar zxvf data.tar.gz; \
		tar zxvf control.tar.gz -C CONTROL; \
		rm debian-binary control.tar.gz data.tar.gz
	cat opkg_tgz/CONTROL/postinst > temp
	echo "echo 'You have installed Opkg. For best results, please run:'" >> temp
	echo "echo '	opkg update'" >> temp
	echo "echo '	opkg install opkg'" >> temp
	echo "rm /system/bin/opkg-install" >> temp
	mv temp opkg_tgz/system/bin/opkg-install
	chmod +x opkg_tgz/system/bin/opkg-install
	rm -rf opkg_tgz/CONTROL
	#for file in opkg_tgz/system/etc/opkg/*.opkg-new; do mv "$$file" "$${file%.opkg-new}"; done
	cd opkg_tgz; fakeroot tar --owner=root --group=root -zcvf ../opkg.tgz *
	rm -rf opkg_tgz
