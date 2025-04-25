include $(TOPDIR)/rules.mk

PKG_NAME:=unet-rrm
PKG_RELEASE:=1

PKG_MAINTAINER:=John Crispin <john@phrozen.org>

include $(INCLUDE_DIR)/package.mk

define Package/unet-rrm
  SECTION:=net
  CATEGORY:=Network
  TITLE:=unet rrm_nr distribution
  DEPENDS:=+unetmsg
endef

define Package/unet-rrm/description
	unetd based RRM NR distribution daemon
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile/Default

endef
Build/Compile = $(Build/Compile/Default)

define Package/unet-rrm/install
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,unet-rrm))
