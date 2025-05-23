include $(TOPDIR)/rules.mk

PKG_NAME:=uwsd

PKG_SOURCE_URL=https://github.com/jow-/uwsd.git
PKG_MIRROR_HASH:=f456cb5951bf8b0c3b3cad18664b587bdb8faddd35ce2ef7d7ff804dc1ec711d
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2025-05-23
PKG_SOURCE_VERSION:=f98f3f1b8f4b3e949da447f943d0672774417929

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
