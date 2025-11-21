#
# Copyright (C) 2019-2025 The Sirpdboy Team <herboy2008@gmail.com>    
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk
THEME_NAME:=kucat
THEME_TITLE:=Kucat Theme
PKG_NAME:=luci-theme-$(THEME_NAME)
LUCI_TITLE:=Kucat Theme by sirpdboy
LUCI_DEPENDS:=+wget +curl +jsonfilter
PKG_VERSION:=3.1.2
PKG_RELEASE:=20251119

define Package/luci-theme-$(THEME_NAME)/conffiles
/www/luci-static/resources/background/
/www/luci-static/kucat/background/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# 覆盖默认的 install，确保 RPCD 脚本有执行权限
define Package/luci-theme-$(THEME_NAME)/install
	$(call Package/luci-theme-$(THEME_NAME)/install/Default, $(1))
	# 确保 RPCD 脚本有执行权限
	chmod +x $(1)/usr/libexec/rpcd/luci.kucatget 2>/dev/null || true
endef

# 自定义 postinst，在安装后设置权限并重启服务
define Package/luci-theme-$(THEME_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	chmod +x /usr/libexec/rpcd/luci.kucatget 2>/dev/null
	/etc/init.d/rpcd restart 2>/dev/null
	rm -f /tmp/luci-indexcache.* 2>/dev/null
	rm -rf /tmp/luci-modulecache/ 2>/dev/null
	killall -HUP rpcd 2>/dev/null
}
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
