# 云调试 HAP 签名踩坑与解决（2026-06-27）

## 现象

云调试上传报错：
> 不支持上传鸿蒙应用Debug软件包，仅支持上传Release包。

## 诊断

打开 HAP（zip 格式）查 `module.json`，关键字段：
```json
"debug": false,
"buildMode": "release"
```

**HAP 内部已经是 release 模式**。云调试仍报 Debug 包的真实原因：**云调试按"签名证书类型"判定**——
- 用**调试证书 + 调试 Profile** 签的 HAP → 云调试识别为 **Debug 包**（即使内部 `buildMode: release`）→ 拒收
- 用**发布证书 + 发布 Profile** 签的 HAP → 云调试识别为 **Release 包** → 接受

⚠️ **本项目踩过的错路**：最初按本笔记 Step 2 选了"调试证书"，签名构建成功，HAP 内 `buildMode: release`，但云调试仍报 Debug 包。修正后必须用**发布证书 + 发布 Profile**。

## DevEco 自动签名为什么走不通

DevEco → Signing Configs → "Automatically generate signature" 报错：
> 缺少设备导致无法新建profile文件，请先通过IP或USB连接设备。

自动签名机制需要本地连一台 HarmonyOS 真机做设备 UDID 注册，颁"调试 Profile"。本项目场景：
- 本地真机太旧、升不到 HarmonyOS 7
- 云调试真机不在 DevEco 的本地设备列表里

→ 自动签名堵死，**必须走手动签名**。

---

## 解决方案 · 手动签名（Release 证书，**无需本地设备**）

### Step 1 · 本地生成密钥库与 CSR

DevEco 菜单：**Build → Generate Key And CSR**

1. Key store path → New → 选个保存位置，命名 `spatialboutique.jks`
2. 填密码（记牢，下一步要用）→ 确认密码
3. 别名 Alias：`spatial_key`（自定义，记牢）
4. Validity：25 年
5. 证书信息（First/Last Name、Organization Unit、Organization、City、State、Country 两字母）随便填合规值
6. 下一步 → 选刚生成的 jks → 输出 `.csr` 文件路径（如 `spatialboutique.csr`）
7. 完成，得到 `.jks` 和 `.csr` 两个文件

### Step 2 · AGC 申请**发布证书** `.cer`

⚠️ **必须选"发布证书"，不是调试证书**。云调试按证书类型判 Debug/Release，调试证书签的包会被识别为 Debug 拒收。

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/agconnect/)
2. 右上角 **用户与访问 → 证书管理**
3. **新增证书** → 类型选 **"发布证书"** → 上传 `spatialboutique.csr`
4. 提交 → 等几秒 → 下载颁发的 `.cer` 文件

> **关键修正（2026-06-27）**：实测调试和发布 Profile **都必填设备 UDID**。AGC 不会对云调试设备自动预授权，必须在 AGC 手动注册云调试设备的 UDID 才能颁 Profile。

### Step 2.5 · 拿云调试真机 UDID（必做）

**路径 X · 云调试 Web UI 直接看**：
进入设备后找「设备信息」「Device Info」面板，UDID 通常是 64 位字母数字串，直接复制。

**路径 Y · hdc 连云调试设备后查**：
1. 云调试 UI 找 connect-key（形如 `IP:port`）
2. 本机 Terminal：
   ```
   hdc tconn IP:port
   hdc list targets          # 确认连上
   hdc shell bm get --udid   # 取 UDID
   ```

**兜底**：云调试 UDID 拿不到时，临时借一台 HarmonyOS 7 真机 USB 连 DevEco，用自动签名自动注册 UDID（之后再切手动签名也复用这个 Profile）。

### Step 2.6 · 把 UDID 注册到 AGC

AGC → 用户与访问 → **设备管理 → 添加设备** → 设备名随意 + UDID 粘贴 → 提交。

### Step 3 · AGC 申请**发布 Profile** `.p7b`

⚠️ **必须选"发布 Profile"（或叫"指定设备发布"），不是调试 Profile**。

1. **用户与访问 → Profile 管理**
2. **新增 Profile**：
   - 类型：**发布 Profile**（指定设备发布）
   - 应用：选 `com.example.spatialboutique`（你的工程，需先在 AGC 创建同 bundleName 的应用）
   - 证书：选 Step 2 颁发的**发布证书**
   - 设备：选你已注册 UDID 的云调试设备
3. 提交 → 下载 `.p7b`

> ⚠️ **前置**：你的 AGC 项目里必须已经创建了 bundleName=`com.example.spatialboutique` 的应用。如果没创建：
> AGC → 我的项目 → 添加项目 → 创建 HarmonyOS 应用 → 包名填 `com.example.spatialboutique`

### Step 4 · DevEco 配置手动签名

DevEco → **File → Project Structure → Project → Signing Configs**

- 选 **"Manually configure"**（手动配置）
- **Store File**：Step 1 的 `.jks`
- **Store Password**：Step 1 密码
- **Key Alias**：Step 1 别名 `spatial_key`
- **Key Password**：同 Store Password（或单独设的）
- **Sign Alg**：`SHA256withECDSA`（默认）
- **Profile File**：Step 3 的 `.p7b`
- **Certpath File**：Step 2 的 `.cer`
- OK → Sync

### Step 5 · Release 构建（这次会产出 signed HAP）

DevEco Terminal：
```bash
hvigorw --mode module -p product=default -p buildMode=release assembleHap --no-daemon
```

产物：`entry/build/default/outputs/default/entry-default-signed.hap`（注意从 `-unsigned` 变 `-signed`）

### Step 6 · 验证签名

```bash
# DevEco Terminal
unzip -p entry/build/default/outputs/default/entry-default-signed.hap module.json | grep -iE "debug|buildMode|signature"
```

应见 `"debug": false` + `"buildMode": "release"`。文件名带 `-signed`。

### Step 7 · 上传云调试

此时 HAP 是「release + 已签名」，云调试应接受。

---

## 常见踩坑

| 报错 | 原因 | 解决 |
|---|---|---|
| AGC 找不到 `com.example.spatialboutique` 应用 | 没在 AGC 创建对应应用 | AGC → 我的项目 → 创建 HarmonyOS 应用，bundleName 与工程一致 |
| Profile 必填设备 UDID 但云调试 UDID 不可见 | 不同 AGC 版本字段不同 | 云调试进入设备后看「设备信息」面板；或用 hdc tconn + `bm get --udid`；兜底借真机用自动签名注册一次 |
| Certpath 上传失败 | CSR 与 AGC 账号主体不一致 | 用同一开发者账号登录 DevEco 和 AGC |
| 构建报 "keystore password was incorrect" | DevEco 缓存了旧密码 | File → Invalidate Caches → Restart |
| 上传云调试仍报 Debug | signed HAP 文件没覆盖到位 | 验证 Step 6，确认 `-signed.hap` 文件名 |

---

## 验证完成后

整套签名是一次性配置，之后所有 release 构建都自动产出 signed HAP。无需重复 Step 1-4。
