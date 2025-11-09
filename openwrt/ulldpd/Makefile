include $(TOPDIR)/rules.mk

PKG_NAME:=ulldpd
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=John Crispin <john@phrozen.org>

PKG_SOURCE_URL=https://github.com/herbetom/ulldpd.git
PKG_MIRROR_HASH:=7b530e00e970f89e50bda2f61223b3fd93cb081e4f87c20a64a1f1e21cbd770e
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2025-11-09
PKG_SOURCE_VERSION:=51a3f8fe4efef3ad4f6c2013c54a225f805b1b8c

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ulldpd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=OpenWrt LLDP Daemon
  DEPENDS:=+libubox +libubus +libblobmsg-json +libuci
endef

define Package/ulldpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ulldpd $(1)/usr/sbin/
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,ulldpd))
