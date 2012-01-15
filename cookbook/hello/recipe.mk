# exports

EXPORT_PACKAGE	+= $~/package/*.yml

define RECIPE

# common targets

.PHONY: $~/package/*.yml
$~/package/*.yml:
	cd ${DIR_REPO}; cat ${TOP}/$$@ | opkg-buildyaml ${TOP}/$~/build

endef

$(eval ${RECIPE})
