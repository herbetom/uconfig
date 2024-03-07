include $(TOPDIR)/rules.mk

PKG_NAME:=uwsd

PKG_SOURCE_URL=https://github.com/jow-/uwsd.git
PKG_MIRROR_HASH:=56ad2aa117f8330778620de2c5ce4a4584b032203f85bf55b5b802e913f74c3b
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-02-09
PKG_SOURCE_VERSION:=c32c32f6ce8921ceceaba414dc6e9bc18a925816

PKG_MAINTAINER:=Jo-Philipp Wich <jo@mein.io>
PKG_LICENSE:=ISC

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/uwsd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=uwsd
  DEPENDS:=+libubox +ucode +libopenssl
endef

CMAKE_OPTIONS+=-DDEBUG=YES -DCMAKE_BUILD_TYPE=Debug
EXTRA_CFLAGS=-Wno-error=unused-function

define Package/uwsd/install
	$(INSTALL_DIR) $(1)/usr/sbin 
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/uwsd $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,uwsd))
