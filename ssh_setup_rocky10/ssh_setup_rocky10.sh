#!/bin/bash
###############################################################################
# ssh_setup_rocky10.sh
#
# 用途  ：为 Rocky Linux 10 集群一键配置 SSH 免密 + 安全加固
# 适用  ：Kubernetes / RKE2 / KubeKey / 通用运维场景
# 密钥  ：Ed25519（Rocky 10 默认 DEFAULT 加密策略原生支持）
# 作者  ：Tang_zhiang AI Assistant
#
# 用法  ：
#   1) 在「主控节点」以 root 身份执行
#   2) 修改下方 HOSTS 数组为你的真实节点列表
#   3) bash ssh_setup_rocky10.sh
#
# 注意  ：脚本不会破坏已有可用密钥；只在必要时生成新密钥。
###############################################################################

set -u

# ===================== 用户配置区 =====================
# 所有节点（主控 + 远端），主控节点放在第一个
HOSTS=(
    k8s03-master
    k8s01-master
    k8s02-master
    k8s04-worker
    k8s05-worker
    k8s06-worker
)

# 远程登录用户（K8s 场景通常为 root）
SSH_USER="root"

# 使用的密钥类型（Rocky 10 强烈推荐 ed25519）
KEY_TYPE="ed25519"
KEY_PATH="${HOME}/.ssh/id_ed25519"

# sshd 配置目录（Rocky 9/10 使用 drop-in 目录）
SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
SSHD_DROPIN_FILE="${SSHD_DROPIN_DIR}/01-ssh-hardening.conf"
# ======================================================

# ----------------- 颜色输出 -----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[ OK ]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ----------------- 前置检查 -----------------
preflight_check() {
    log_info "执行前置检查..."

    # 必须是 root（K8s 节点间 SSH 通常需要）
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用 root 用户执行此脚本"
        exit 1
    fi

    # 检查必要命令
    for cmd in ssh ssh-keygen ssh-copy-id ping; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "缺少命令: $cmd，请先安装 openssh-clients 和 iputils"
            exit 1
        fi
    done

    # 检查 sshd 服务
    if ! systemctl is-active --quiet sshd; then
        log_warn "sshd 未运行，尝试启动..."
        systemctl enable --now sshd || {
            log_error "sshd 启动失败，请检查 /etc/ssh/sshd_config"
            exit 1
        }
    fi

    # 显示当前加密策略（Rocky 10 关键）
    if command -v update-crypto-policies >/dev/null 2>&1; then
        local policy
        policy=$(update-crypto-policies --show 2>/dev/null || echo "unknown")
        log_info "当前系统加密策略: ${policy}"
        if [[ "$policy" == "FUTURE" ]]; then
            log_warn "FUTURE 策略仅允许 ML-KEM 混合算法，连接旧节点可能失败"
            log_warn "如遇到兼容性问题，可切回 DEFAULT: update-crypto-policies --set DEFAULT"
        fi
    fi

    log_ok "前置检查通过"
}

# ----------------- 密钥管理 -----------------
setup_ssh_key() {
    log_info "检查本地 SSH 密钥..."

    local pub_path="${KEY_PATH}.pub"

    if [[ -f "$KEY_PATH" && -f "$pub_path" ]]; then
        # 验证密钥有效性
        if ssh-keygen -l -f "$KEY_PATH" >/dev/null 2>&1; then
            local key_info
            key_info=$(ssh-keygen -l -f "$pub_path")
            log_ok "发现可用密钥: ${key_info}"
            return 0
        else
            log_warn "已有密钥文件损坏，将重新生成"
            mv -f "$KEY_PATH" "${KEY_PATH}.broken.$(date +%s)" 2>/dev/null || true
            mv -f "$pub_path" "${pub_path}.broken.$(date +%s)" 2>/dev/null || true
        fi
    fi

    # 生成新密钥（无 passphrase，适合自动化场景）
    log_info "生成新的 ${KEY_TYPE} 密钥..."
    ssh-keygen -t "$KEY_TYPE" -N "" -f "$KEY_PATH" -C "rocky10-$(hostname)-$(date +%F)"
    chmod 600 "$KEY_PATH"
    chmod 644 "$pub_path"
    log_ok "密钥生成完成: ${KEY_PATH}"
}

# ----------------- 本地 .ssh 权限 -----------------
setup_local_permissions() {
    log_info "设置本地 ~/.ssh 目录权限..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    chmod 700 "${HOME}" 2>/dev/null || true  # SSH 要求 home 不可被 group/other 写

    # 确保 authorized_keys 存在且权限正确
    touch "${HOME}/.ssh/authorized_keys"
    chmod 600 "${HOME}/.ssh/authorized_keys"

    # 把本机公钥也加入本机 authorized_keys（允许 ssh 到 localhost）
    local pub_key
    pub_key=$(cat "${KEY_PATH}.pub")
    if ! grep -qF "$pub_key" "${HOME}/.ssh/authorized_keys"; then
        echo "$pub_key" >> "${HOME}/.ssh/authorized_keys"
        log_ok "本机公钥已加入 authorized_keys"
    fi
    log_ok "本地权限设置完成"
}

# ----------------- 远端节点准备 -----------------
prepare_remote_host() {
    local host="$1"
    log_info "准备远端节点: ${host}"

    # 测试连通性
    if ! ping -c 2 -W 3 "$host" >/dev/null 2>&1; then
        log_error "无法 ping 通 ${host}，请检查 /etc/hosts 或 DNS"
        return 1
    fi

    # 用 ssh 在远端创建目录、设置权限
    # 首次连接可能需要密码
    ssh -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        "${SSH_USER}@${host}" "
        set -e
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        chmod 700 ~
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        echo 'Remote prep OK on $(hostname)'
    " || {
        log_error "远端准备失败: ${host}（可能密码错误或 sshd 配置问题）"
        return 1
    }
    log_ok "远端节点准备完成: ${host}"
}

# ----------------- 分发公钥 -----------------
distribute_public_key() {
    local host="$1"
    log_info "分发公钥到: ${host}"

    ssh-copy-id -i "${KEY_PATH}.pub" \
        -o StrictHostKeyChecking=accept-new \
        "${SSH_USER}@${host}" >/dev/null 2>&1 && {
        log_ok "公钥分发成功: ${host}"
        return 0
    }

    # ssh-copy-id 失败时尝试手动方式
    log_warn "ssh-copy-id 失败，尝试手动分发..."
    local pub_content
    pub_content=$(cat "${KEY_PATH}.pub")
    ssh -o StrictHostKeyChecking=accept-new \
        "${SSH_USER}@${host}" "
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        echo '${pub_content}' >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    " && log_ok "手动分发成功: ${host}" || {
        log_error "公钥分发失败: ${host}"
        return 1
    }
}

# ----------------- 验证免密登录 -----------------
verify_ssh() {
    local host="$1"
    log_info "验证免密登录: ${host}"

    local output
    output=$(ssh -o BatchMode=yes \
                  -o ConnectTimeout=10 \
                  -o StrictHostKeyChecking=accept-new \
                  "${SSH_USER}@${host}" \
                  "hostname && date" 2>&1)

    if [[ $? -eq 0 ]]; then
        log_ok "免密验证通过 [${host}]: ${output}"
        return 0
    else
        if echo "$output" | grep -qi "password\|passphrase"; then
            log_error "免密验证失败 [${host}]: 仍然要求输入密码"
        else
            log_error "免密验证失败 [${host}]: ${output}"
        fi
        return 1
    fi
}

# ----------------- 生成 sshd 安全配置 -----------------
generate_sshd_hardening() {
    log_info "生成 sshd 安全加固配置..."

    if [[ ! -d "$SSHD_DROPIN_DIR" ]]; then
        mkdir -p "$SSHD_DROPIN_DIR"
    fi

    cat > "$SSHD_DROPIN_FILE" <<'EOF'
# Rocky Linux 10 SSH 安全加固配置
# 由 ssh_setup_rocky10.sh 生成
# 优先级高于 /etc/ssh/sshd_config 中的默认值

# === 认证方式 ===
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes

# === 密钥算法（Rocky 10 DEFAULT 策略推荐） ===
# Ed25519 优先，兼容 RSA-SHA2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_rsa_key

# === 会话安全 ===
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
LoginGraceTime 30

# === 日志 ===
LogLevel VERBOSE
EOF

    chmod 644 "$SSHD_DROPIN_FILE"
    log_ok "sshd 配置已写入: ${SSHD_DROPIN_FILE}"

    # 验证配置语法
    if sshd -t 2>/dev/null; then
        log_ok "sshd 配置语法检查通过"
    else
        log_warn "sshd 配置可能有问题，请运行 'sshd -t' 检查"
    fi
}

# ----------------- 同步 sshd 配置到所有节点 -----------------
sync_sshd_config() {
    log_info "同步 sshd 安全配置到所有节点..."

    for host in "${HOSTS[@]}"; do
        [[ "$host" == "$(hostname)" ]] && continue

        scp -o StrictHostKeyChecking=accept-new \
            "$SSHD_DROPIN_FILE" \
            "${SSH_USER}@${host}:${SSHD_DROPIN_FILE}" >/dev/null 2>&1 && {
            log_ok "配置已同步: ${host}"
        } || {
            log_warn "配置同步失败: ${host}（后续可手动同步）"
        }
    done
}

# ----------------- 重载 sshd -----------------
reload_sshd() {
    log_info "重载 sshd 服务..."
    systemctl reload sshd 2>/dev/null || systemctl restart sshd
    sleep 1
    if systemctl is-active --quiet sshd; then
        log_ok "sshd 服务运行正常"
    else
        log_error "sshd 服务异常，请检查配置"
        systemctl status sshd --no-pager
    fi
}

# ----------------- 全量验证 -----------------
full_verification() {
    log_info "执行全量免密验证..."
    echo "--------------------------------------------------------------"

    local failed=0
    for host in "${HOSTS[@]}"; do
        if ! verify_ssh "$host"; then
            failed=$((failed + 1))
        fi
    done

    echo "--------------------------------------------------------------"
    if [[ $failed -eq 0 ]]; then
        log_ok "全部 ${#HOSTS[@]} 个节点免密验证通过！"
    else
        log_error "${failed} 个节点验证失败"
        return 1
    fi
}

# ----------------- 高级模式：节点间互信 -----------------
setup_inter_node_trust() {
    log_info "配置节点间互信（每个节点都拥有所有公钥）..."

    # 在主控节点收集所有节点的公钥
    local all_keys_file="/tmp/all_ssh_keys_$$.txt"
    : > "$all_keys_file"

    for host in "${HOSTS[@]}"; do
        local remote_pub
        remote_pub=$(ssh -o BatchMode=yes \
                          -o ConnectTimeout=10 \
                          "${SSH_USER}@${host}" \
                          "cat ~/.ssh/id_ed25519.pub 2>/dev/null || echo ''")
        if [[ -n "$remote_pub" ]]; then
            echo "$remote_pub" >> "$all_keys_file"
        fi
    done

    # 把本机公钥也加入
    cat "${KEY_PATH}.pub" >> "$all_keys_file"

    # 去重后分发到所有节点
    local unique_keys="/tmp/unique_keys_$$.txt"
    awk '!seen[$0]++' "$all_keys_file" > "$unique_keys"

    local key_count
    key_count=$(wc -l < "$unique_keys")
    log_info "共收集到 ${key_count} 个唯一公钥，分发到所有节点..."

    for host in "${HOSTS[@]}"; do
        scp -o BatchMode=yes -o ConnectTimeout=10 \
            "$unique_keys" \
            "${SSH_USER}@${host}:~/.ssh/authorized_keys.tmp" >/dev/null 2>&1 && {
            ssh -o BatchMode=yes "${SSH_USER}@${host}" "
                cat ~/.ssh/authorized_keys.tmp >> ~/.ssh/authorized_keys
                sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys
                rm -f ~/.ssh/authorized_keys.tmp
                chmod 600 ~/.ssh/authorized_keys
            "
            log_ok "节点间互信完成: ${host}"
        } || {
            log_warn "节点间互信失败: ${host}"
        }
    done

    rm -f "$all_keys_file" "$unique_keys"
}

# 预信任所有节点（消除 yes 提示）
preload_known_hosts() {
    log_info "预加载所有节点的 SSH 主机密钥到 known_hosts..."

    local failed=0
    local self
    self=$(hostname)

    for host in "${HOSTS[@]}"; do
        [[ "$host" == "$self" ]] && continue

        log_info "信任节点: ${host}"

        if ssh -o StrictHostKeyChecking=no \
               -o BatchMode=yes \
               -o ConnectTimeout=5 \
               "${SSH_USER}@${host}" "true" >/dev/null 2>&1; then
            log_ok "主机密钥已信任: ${host}"
        else
            log_warn "无法连接 ${host}，跳过 known_hosts 预加载"
            failed=$((failed + 1))
        fi
    done

    # 确保 known_hosts 权限正确
    if [[ -f "${HOME}/.ssh/known_hosts" ]]; then
        chmod 644 "${HOME}/.ssh/known_hosts"
    fi

    if [[ $failed -eq 0 ]]; then
        log_ok "所有节点主机密钥预加载完成"
    else
        log_warn "${failed} 个节点预加载失败（不影响后续流程）"
    fi
}




# ===================== 主流程 =====================
main() {
    echo "=============================================================="
    echo "  Rocky Linux 10 SSH 免密配置脚本"
    echo "  主控节点: $(hostname)  ($(ip route get 1 | awk '{print $7; exit}'))"
    echo "  目标节点: ${HOSTS[*]}"
    echo "=============================================================="
    echo

    preflight_check
    setup_ssh_key
    setup_local_permissions
    generate_sshd_hardening
    
    # 1) 准备远端 + 分发公钥
    local prep_failed=0
    for host in "${HOSTS[@]}"; do
        [[ "$host" == "$(hostname)" ]] && continue
        if ! prepare_remote_host "$host"; then
            prep_failed=$((prep_failed + 1))
            continue
        fi
        distribute_public_key "$host"
    done

    # 2) 同步并应用 sshd 配置
    sync_sshd_config
    reload_sshd
    preload_known_hosts
    
    # 3) 全量验证
    full_verification

    # 4) 可选：配置节点间互信
    echo
    read -r -p "是否配置「节点间互信」（各节点可互相免密 SSH）? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        setup_inter_node_trust
        echo
        log_info "再次验证所有节点互信..."
        full_verification
    fi

    echo
    echo "=============================================================="
    log_ok "脚本执行完毕"
    echo
    echo "后续建议："
    echo "  1. 确认所有节点 sshd 配置生效"
    echo "  2. 如需启用 FIPS/后量子策略，运行："
    echo "     update-crypto-policies --set FUTURE"
    echo "  3. 查看日志: journalctl -u sshd -f"
    echo "=============================================================="
}

main "$@"
