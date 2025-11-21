# 多 WAN 接口增强说明

## 修改概述

本次修改为 `luci.kucatget` RPCD 后端脚本添加了完整的**多 WAN 接口支持**，解决了新版本代码在多 WAN 环境下灵活性不足的问题。

## 修改日期
2025-11-19

## 新增功能

### 1. WAN 接口自动检测
```bash
get_available_wan_interfaces()
```
- 自动检测所有活跃的 WAN 接口
- 通过 `ip route` 和 `ip link` 验证接口状态
- 支持多 WAN 负载均衡和主备切换场景

### 2. HTTP 工具兼容性检测
```bash
check_http_tool()
```
- 优先使用 `curl`
- 自动降级到 `wget`
- 确保在不同系统环境下的兼容性

### 3. 智能 HTTP 请求函数
```bash
http_request(url)
http_request_with_header(url, header)
```
- 支持多 WAN 接口轮询
- 自动重试失败的接口
- 支持自定义 HTTP header（用于 Unsplash API）
- curl/wget 自动降级

## 修改的函数

### 1. `fetch_daily_word()`
- ✅ 所有 6 种每日一言 API 调用改用 `http_request()`
- ✅ 支持多 WAN 接口自动切换

### 2. `fetch_PicUrl()`
- ✅ 5 种壁纸源全部改用 `http_request()` 或 `http_request_with_header()`
- ✅ Unsplash API 支持自定义 Authorization header
- ✅ 所有 API 调用支持多 WAN 接口

### 3. `try_down_pic()`
- ✅ 壁纸下载支持多 WAN 接口轮询
- ✅ 增加 wget 降级支持
- ✅ 超时时间从 3 秒延长到 30 秒（更适合大文件下载）

## 技术特性

### 多 WAN 接口轮询机制
```bash
for iface in $interfaces; do
    result=$(curl --interface "$iface" -s --connect-timeout 5 "$url")
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        echo "$result"
        return 0  # 成功立即返回
    fi
done
```

### 工具降级策略
1. **优先 curl**：支持接口绑定（`--interface`）
2. **降级 wget**：不支持接口绑定，但提供基础功能

### 超时控制
- API 请求：5 秒连接超时，15 秒总超时
- 文件下载：30 秒总超时

## 适用场景

### ✅ 完美支持
- 单 WAN 环境
- 双 WAN 负载均衡
- 双 WAN 主备切换
- 多 WAN 策略路由
- VPN + WAN 共存

### 🔥 典型场景示例

#### 场景 1：双 WAN 主备
```
WAN1 (PPPoE): 主线路，但国际访问受限
WAN2 (4G):    备用线路，国际访问正常

行为：
1. 尝试 WAN1 访问 api.unsplash.com → 超时
2. 自动切换 WAN2 → 成功 ✅
```

#### 场景 2：多 WAN 负载均衡
```
WAN1: 电信
WAN2: 联通
WAN3: 移动

行为：
按顺序尝试所有接口，使用第一个成功的
```

## 性能对比

| 指标 | 修改前 | 修改后 |
|------|--------|--------|
| 代码行数 | 335 行 | 455 行 |
| 多 WAN 支持 | ❌ | ✅ |
| 接口轮询 | ❌ | ✅ |
| 工具降级 | 仅 curl | curl/wget |
| API 超时 | 3 秒 | 5-15 秒 |
| 下载超时 | 3 秒 | 30 秒 |

## 兼容性

### 向后兼容
- ✅ 单 WAN 环境完全兼容
- ✅ 原有功能不受影响
- ✅ 配置文件无需修改

### 依赖要求
```makefile
LUCI_DEPENDS:=+curl
# 可选：+wget（作为降级方案）
```

## 测试建议

### 1. 单 WAN 测试
```bash
# 检查壁纸下载
ubus call luci.kucatget get_url

# 检查每日一言
ubus call luci.kucatget get_word
```

### 2. 多 WAN 测试
```bash
# 查看检测到的接口
ip route | grep default

# 模拟主接口故障
ifdown wan1

# 验证自动切换
ubus call luci.kucatget get_url
```

### 3. 日志调试
```bash
# 查看 RPCD 日志
logread | grep kucatget
```

## 注意事项

1. **接口顺序**：按 `ip route` 返回的顺序尝试
2. **超时累积**：多接口轮询会累积超时时间
3. **wget 限制**：wget 不支持 `--interface`，无法绑定接口

## 回滚方法

如果需要恢复原版本：
```bash
cd /home/zag/OpenWrt/immortalwrt/master/package/Applications/sirpdboy/luci-theme-kucat
git checkout root/usr/libexec/rpcd/luci.kucatget
```

## 维护建议

1. 定期同步上游代码
2. 如果上游添加新的壁纸源，记得使用 `http_request()` 函数
3. 保持与上游的功能一致性

## 作者
- 原始代码：sirpdboy team
- 多 WAN 增强：基于旧版本逻辑移植

## 许可证
Apache License 2.0
