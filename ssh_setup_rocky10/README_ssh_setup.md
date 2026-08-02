# SSH 免密配置脚本 — Rocky Linux 10 专用

## 这个脚本解决了什么问题？

你之前用的 `sshUserSetup.sh` 是 **2005 年为 Oracle RAC 写的老脚本**，存在三个致命问题：

| 问题 | 后果 |
|---|---|
| 强制使用 RSA 1024 位 | OpenSSH ≥ 8.8 直接拒绝 → `Invalid key length` |
| 不支持 Ed25519 | 无法利用现代安全算法 |
| 多次 SSH/SCP 交互 | 6 个节点要输 12+ 次密码 |

**Rocky Linux 10 默认 OpenSSH 9.9+**，已经彻底淘汰 RSA 1024，所以老脚本必然报错。

## 新脚本的设计思路

```
主控节点 (k8s03-master)
    │
    ├── 1. 生成 Ed25519 密钥（现代、安全、Rocky 10 原生支持）
    ├── 2. 设置本地 ~/.ssh 权限（SSH 硬性要求）
    ├── 3. 生成 sshd 安全加固配置（drop-in 文件）
    ├── 4. SSH 到各节点创建目录 + 设置权限
    ├── 5. 用 ssh-copy-id 分发公钥
    ├── 6. 同步 sshd 配置到所有节点
    ├── 7. 重载 sshd
    └── 7. 自动验证免密登录
```

## 使用方法

### 1. 修改节点列表

编辑脚本开头的 `HOSTS` 数组：

```bash
HOSTS=(
    k8s03-master   # 主控节点放第一个
    k8s01-master
    k8s02-master
    k8s04-worker
    k8s05-worker
    k06-worker
)
```

### 2. 执行脚本

```bash
# 上传到主控节点
scp ssh_setup_rocky10.sh root@k8s03-master:/root/

# 在 k8s03-master 上执行
ssh root@k8s03-master
chmod +x ssh_setup_rocky10.sh
./ssh_setup_rocky10.sh
```

### 3. 首次运行需要做什么？

首次运行时，脚本 SSH 到各节点**还没有免密**，所以会提示输入密码：

```
root@k8s01-master's password:
```

**每个节点只需输入一次**（用于创建目录 + ssh-copy-id），之后全自动。

## 脚本做了哪些安全加固？

生成的 `/etc/ssh/sshd_config.d/01-ssh-hardening.conf`：

| 配置项 | 值 | 说明 |
|---|---|---|
| `PubkeyAuthentication` | yes | 启用密钥认证 |
| `PasswordAuthentication` | **no** | 禁止密码登录（防暴力破解） |
| `PermitRootLogin` | yes | 允许 root（K8s 需要，可改 no） |
| `X11Forwarding` | no | 关闭 X11 转发 |
| `MaxAuthTries` | 3 | 限制尝试次数 |
| `ClientAliveInterval` | 300 | 5 分钟无操作断连 |

## Rocky Linux 10 特别注意事项

### 加密策略

Rocky 10 引入**后量子密码学 (PQC)** 策略：

```bash
# 查看当前策略
update-crypto-policies --show

# DEFAULT  = 混合 PQC + 传统算法（推荐，兼容性好）
# FUTURE   = 仅 ML-KEM 混合算法（会断连不支持 PQC 的旧节点）
# LEGACY   = 允许更多旧算法
```

⚠️ **如果你的集群混入了旧系统（如 CentOS 7），不要切到 FUTURE 策略**

### sshd 配置优先级

Rocky 9/10 的 sshd 配置加载顺序：

```
/etc/ssh/sshd_config          ← 主文件（通常不动）
/etc/ssh/sshd_config.d/*.conf ← drop-in 文件（数字越小优先级越高）
```

脚本生成的 `01-ssh-hardening.conf` 以 `01-` 开头，确保**优先于**系统默认的 `50-redhat.conf`。

### 权限要求（SSH 硬性规定）

```
/root           700  ← 不能是 777 或 775
/root/.ssh      700
/root/.ssh/authorized_keys  600
```

任何一个不对，SSH 都会**静默回退到密码登录**，这是你之前踩坑的根本原因之一。

## 故障排查

### 仍然要求输入密码

```bash
# 在客户端调试
ssh -vvv root@k8s01-master 2>&1 | grep -E "Offering|Authenticated|permission"

# 在服务器端检查
journalctl -u sshd -f
ls -la /root/.ssh/
ls -ld /root
```

### `Permission denied (publickey)`

99% 是权限问题，检查三样东西：
1. `~/.ssh/authorized_keys` 是否是 600
2. `~/.ssh/` 是否是 700
3. `~/` 是否被 group/other 写了

### 节点间互信失败

脚本最后会问是否配置节点间互信。如果选 `y` 后失败，手动执行：

```bash
# 在每个节点上都生成密钥
ssh root@k8s01-master "ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519"

# 然后把所有公钥收集到一个文件，分发到所有节点
```

五、一个“终极安心验证”（建议你跑一次）

for h in k8s01-master k8s02-master k8s03-master \
         k8s04-worker k8s05-worker k8s06-worker; do
  echo "=== $h ==="
  ssh -o BatchMode=yes root@$h "hostname"
done

✅ 不提示 yes

✅ 不提示 password

✅ 每台都返回主机名

→ **这就是“免密 + 自动信任”的完成态**



## 与老脚本的关键区别

| 对比项 | 老脚本 sshUserSetup.sh | 新脚本 ssh_setup_rocky10.sh |
|---|---|---|
| 密钥算法 | RSA 1024（已淘汰）| **Ed25519（现代标准）** |
| OpenSSH 9.9 兼容 | ❌ Invalid key length | ✅ 原生支持 |
| 加密策略感知 | ❌ 无 | ✅ 自动检测并提示 |
| 权限处理 | 强制 chmod og-w | ✅ 精确设置 700/600 |
| sshd 配置 | 不处理 | ✅ 生成 drop-in 加固文件 |
| 免密验证 | 简单 date 命令 | ✅ BatchMode 自动检测 |
| 节点间互信 | 可选但很粗暴 | ✅ 优雅收集+去重分发 |
| 密码输入次数 | 12+ 次 | **每个节点仅 1 次** |
| 错误处理 | 基本无 | ✅ 每步检查 + 清晰提示 |
| 代码可读性 | 2005 年 sh 风格 | ✅ 模块化 bash + 颜色日志 |

## 一句话总结

> **删掉那个 20 年前的老脚本，用这个新的。**  
> Ed25519 密钥 + 正确权限 + sshd 加固 = Rocky 10 上一次跑通，永不复发。
