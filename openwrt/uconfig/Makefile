include $(TOPDIR)/rules.mk

PKG_NAME:=uconfig
PKG_RELEASE:=$(COMMITCOUNT)

PKG_FILE_DEPENDS := $(CURDIR)/../../

PKG_MAINTAINER:=John Crispin <john@phrozen.org>
PKG_LICENSE:=ISC

PKG_BUILD_DEPENDS:=python3/host
PYTHON3_PKG_BUILD:=0
HOST_PYTHON3_PACKAGE_BUILD_DEPENDS:=./host-pip-requirements.txt

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_SOURCE_DIR:=$(PKG_BUILD_DIR)/src
CMAKE_BINARY_DIR:=$(PKG_BUILD_DIR)/src

define uconfig/module
	$(INSTALL_DIR) $(1)/etc/uconfig/modules/
	touch $(1)/etc/uconfig/modules/$(2)
endef

define Package/uconfig
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer
  DEPENDS=+ucode-mod-nl80211 +ucode-mod-rtnl +ucode-mod-ubus +ip-full +ip-bridge +ratelimit +qosify +pkgen +nlbwmon
endef

define Package/uconfig-cli
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (CLI)
  DEPENDS=uconfig +cli
endef

define Package/uconfig-websocket
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (WebSocket)
  DEPENDS=uconfig +uwsd +pkgen +uconfig-cli +ucode-mod-log +ucode-mod-math +ucode-mod-digest +uconfig-mod-nlbwmon +unet-rrm +uconfig-mod-fingerprint
endef

define Package/uconfig-client
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (Managed Client)
  DEPENDS=uconfig +uconfig-cli +ucode-mod-log +ucode-mod-math +ucode-mod-digest +uconfig-mod-unetd +unet-rrm
endef

define Package/uconfig-mod-mdns
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (MDNS plugin)
  DEPENDS=uconfig +umdns
endef

define Package/uconfig-mod-lldp
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (LLDP plugin)
  DEPENDS=uconfig +ulldpd
endef

define Package/uconfig-mod-ieee8021x
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (IEEE802.1x plugin)
  DEPENDS=uconfig +ucode-mod-log +ieee8021x
endef

define Package/uconfig-mod-mesh-batman
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (Mesh/Batman plugin)
  DEPENDS=uconfig +kmod-batman-adv
endef

define Package/uconfig-mod-adguardhome
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (adguardhome plugin)
  DEPENDS=uconfig +adguardhome
endef

define Package/uconfig-mod-fingerprint
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (fingerprint plugin)
  DEPENDS=uconfig +ufp +ufp-neigh +udhcpsnoop +uconfig-mod-mdns
endef

define Package/uconfig-mod-unetd
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (unetd plugin)
  DEPENDS=uconfig +unetd +unet-cli +unetmsg
endef

define Package/uconfig-mod-nlbwmon
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (nlbwmon plugin)
  DEPENDS=uconfig +nlbwmon
endef

define Package/uconfig-mod-mesh-easy
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=uConfig
  TITLE:=UCI renderer (mesh-easy plugin)
  DEPENDS=uconfig umapd
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/../../ $(PKG_BUILD_DIR)/
endef

define Build/Configure
        $(call Py3Build/InstallBuildDepends)
	$(call Build/Configure/Default)
endef

define Build/Compile
	$(PKG_BUILD_DIR)/render/generate.sh $(PKG_BUILD_DIR)/render/
endef

define Package/uconfig/conffiles
/etc/uconfig/configs/
/etc/uconfig/certificates/
/etc/uconfig/data/
/etc/uconfig/devices/
endef

define Package/uconfig-websocket/conffiles
/etc/uconfig/webui/webui.json
/etc/uconfig/webui/credentials
endef

define Package/uconfig/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/ $(1)/usr/libexec/uconfig/ $(1)/etc/uconfig/configs $(1)/etc/uconfig/data $(1)/etc/uconfig/devices $(1)/sbin
	$(CP) $(PKG_BUILD_DIR)/render/{ureader,uconfig} $(1)/usr/share/ucode/
	$(CP) $(PKG_BUILD_DIR)/render/lib/* $(1)/usr/share/ucode/uconfig
	$(CP) $(PKG_BUILD_DIR)/render/system/*.uc $(1)/usr/libexec/uconfig
	$(CP) $(PKG_BUILD_DIR)/render/examples $(1)/etc/uconfig
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/render/uconfig_apply $(1)/sbin
	date +%s > $(1)/etc/uconfig/build_time
	$(CP) ./files-render/* $(1)
	$(CP) ./files-tools/* $(1)
endef

define Package/uconfig-cli/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/ $(1)/usr/sbin
	$(CP) $(PKG_BUILD_DIR)/cli $(1)/usr/share/ucode/
	$(LN) /usr/sbin/cli $(1)/usr/sbin/uconfig
endef

define Package/uconfig-client/install
	$(CP) ./files-client/* $(1)
	$(call uconfig/module,$1,uconfig-client)
endef

define Package/uconfig-websocket/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/uconfig $(1)/www-uconfig/
	$(CP) $(PKG_BUILD_DIR)/websocket/ $(1)/usr/share/ucode/uconfig
	$(CP) $(PKG_BUILD_DIR)/webui/* $(1)/www-uconfig/
	$(CP) ./files-websocket/* $(1)

	$(INSTALL_DIR) $(1)/usr/lib/ucode/uconfig/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/utils.so $(1)/usr/lib/ucode/uconfig/

	$(INSTALL_DIR) $(1)/usr/share/ucode/uconfig/templates/services/
	$(CP) $(PKG_BUILD_DIR)/render/modules/webui/* $(1)/usr/share/ucode/uconfig/templates/services/
endef

define Package/uconfig-mod-mdns/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults/ $(1)/usr/share/ucode/uconfig/templates/services/
	$(INSTALL_DIR) $(1)/usr/share/ucode/ureader/
	$(CP) ./modules/mdns.defaults $(1)/etc/uci-defaults/uconfig-mdns
	$(CP) $(PKG_BUILD_DIR)/render/ureader-modules/schemaServiceMdns.uc $(1)/usr/share/ucode/ureader/
	$(CP) $(PKG_BUILD_DIR)/render/modules/mdns/* $(1)/usr/share/ucode/uconfig/templates/services/
endef

define Package/uconfig-mod-fingerprint/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults/ $(1)/usr/share/ucode/uconfig/templates/services/
	$(CP) ./modules/fingerprint.defaults $(1)/etc/uci-defaults/uconfig-fingerprint
	$(CP) $(PKG_BUILD_DIR)/render/modules/fingerprint/* $(1)/usr/share/ucode/uconfig/templates/services/
endef

define Package/uconfig-mod-nlbwmon/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/uconfig/templates/services/
	$(CP) $(PKG_BUILD_DIR)/render/modules/nlbwmon/* $(1)/usr/share/ucode/uconfig/templates/services/
endef

define Package/uconfig-mod-adguardhome/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/uconfig/templates/services/ 
	$(INSTALL_DIR) $(1)/usr/share/ucode/ureader/
	$(INSTALL_DIR) $(1)/usr/share/ucode/cli/modules/uconfig/services/
	$(CP) $(PKG_BUILD_DIR)/render/ureader-modules/schemaServiceAdguardhome.uc $(1)/usr/share/ucode/ureader/
	$(CP) $(PKG_BUILD_DIR)/render/modules/adguardhome/*.uc $(1)/usr/share/ucode/uconfig/templates/services/
	$(CP) $(PKG_BUILD_DIR)/render/modules/adguardhome/*.yaml $(1)/usr/share/ucode/uconfig/
	$(CP) $(PKG_BUILD_DIR)/render/modules/adguardhome/cli-adguardhome.uc $(1)/usr/share/ucode/cli/modules/uconfig/services/adguardhome.uc
	$(call uconfig/module,$1,adguardhome)
endef

define Package/uconfig-mod-lldp/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults/ $(1)/usr/share/ucode/uconfig/templates/services/
	$(INSTALL_DIR) $(1)/usr/share/ucode/ureader/
	$(CP) ./modules/lldp.defaults $(1)/etc/uci-defaults/uconfig-lldp
	$(CP) $(PKG_BUILD_DIR)/render/ureader-modules/schemaServiceLldp.uc $(1)/usr/share/ucode/ureader/
	$(CP) $(PKG_BUILD_DIR)/render/modules/lldp/* $(1)/usr/share/ucode/uconfig/templates/services/
endef

define Package/uconfig-mod-ieee8021x/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/uconfig/templates/services/	$(INSTALL_DIR) $(1)/usr/share/ucode/ureader/
	$(CP) $(PKG_BUILD_DIR)/render/ureader-modules/schemaServiceIeee8021x.uc $(1)/usr/share/ucode/ureader/
	$(CP) $(PKG_BUILD_DIR)/render/modules/ieee8021x/* $(1)/usr/share/ucode/uconfig/templates/services/
endef

define Package/uconfig-mod-unetd/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/uconfig/templates/services/ $(INSTALL_DIR) $(1)/usr/share/ucode/cli/modules/uconfig/
	$(CP) $(PKG_BUILD_DIR)/render/modules/unet/unet.uc $(1)/usr/share/ucode/uconfig/templates/services/
	$(CP) $(PKG_BUILD_DIR)/render/modules/unet/cli-unet.uc $(1)/usr/share/ucode/cli/modules/uconfig/unet.uc
	$(call uconfig/module,$1,unetd)
endef

define Package/uconfig-mod-mesh-batman/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(call uconfig/module,$1,batman-adv)
endef

define Package/uconfig-mod-mesh-easy/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(CP) ./modules/mesh-easy.defaults $(1)/etc/uci-defaults/uconfig-mesh-easy
endef

$(eval $(call BuildPackage,uconfig))
$(eval $(call BuildPackage,uconfig-cli))
$(eval $(call BuildPackage,uconfig-client))
$(eval $(call BuildPackage,uconfig-websocket))
$(eval $(call BuildPackage,uconfig-mod-adguardhome))
$(eval $(call BuildPackage,uconfig-mod-fingerprint))
$(eval $(call BuildPackage,uconfig-mod-ieee8021x))
$(eval $(call BuildPackage,uconfig-mod-lldp))
$(eval $(call BuildPackage,uconfig-mod-mdns))
$(eval $(call BuildPackage,uconfig-mod-mesh-batman))
$(eval $(call BuildPackage,uconfig-mod-unetd))
$(eval $(call BuildPackage,uconfig-mod-nlbwmon))
$(eval $(call BuildPackage,uconfig-mod-mesh-easy))
