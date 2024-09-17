include $(TOPDIR)/rules.mk

PKG_NAME:=ufp
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>

PKG_SOURCE_URL=https://github.com/blogic/ufp.git
PKG_MIRROR_HASH:=bdf8ef71e4d9a60fd27c0180b1a698b9791ac5fe1e0983e9118f2f25c49e1d7d
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-10-01
PKG_SOURCE_VERSION:=618a8d1e11e6b8c6ea31b94e6111ba763d932034

HOST_BUILD_DEPENDS:=ucode/host libubox/host
PKG_BUILD_DEPENDS:=bpf-headers ufp/host
UCODE:=LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(STAGING_DIR_HOSTPKG)/lib/:$(STAGING_DIR_HOST)/lib/ $(STAGING_DIR_HOSTPKG)/bin/ucode

CMAKE_SOURCE_SUBDIR:=src

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ufp
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Device fingerprinting daemon
  DEPENDS:=+ucode +ucode-mod-fs +ucode-mod-struct +libubox +udhcpsnoop
endef

define Package/ufp/conffiles
/etc/config/ufp
endef

define i_Host/Prepare
	$(call Build/Prepare/Default)

	mkdir -p $(HOST_BUILD_DIR)
	$(CP) $(PKG_BUILD_DIR)/src/* $(HOST_BUILD_DIR)/
endef

CMAKE_HOST_OPTIONS += \
	-DCMAKE_SKIP_RPATH=FALSE \
	-DCMAKE_INSTALL_RPATH="${STAGING_DIR_HOST}/lib"

define Package/ufp/install
	$(INSTALL_DIR) $(1)/usr/lib/ucode $(1)/usr/share/ufp
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/lib/ucode/uht.so $(1)/usr/lib/ucode/
	$(UCODE) $(PKG_BUILD_DIR)/scripts/convert-devices.uc $(1)/usr/share/ufp/devices.bin $(PKG_BUILD_DIR)/data/*.json
	$(CP) $(PKG_BUILD_DIR)/files/* $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,ufp))
$(eval $(call HostBuild))
