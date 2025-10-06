include $(TOPDIR)/rules.mk

PKG_NAME:=ulldpd
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=John Crispin <john@phrozen.org>

PKG_SOURCE_URL=https://github.com/herbetom/ulldpd.git
PKG_MIRROR_HASH:=b1966d03b832f2db5ae8d3b152b98eba8138e5e3c3e24c943445655f10d8a047
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-09-30
PKG_SOURCE_VERSION:=8e084de900d93bbb29d0cf79af73dca386cfc318

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
