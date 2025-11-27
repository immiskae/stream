#!/bin/bash
set -e
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

if [[ $EUID -eq 0 ]]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="$HOME/bin"
    mkdir -p "$TARGET_DIR"
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$PATH:$HOME/bin"' >> "$HOME/.bashrc"
        export PATH="$PATH:$HOME/bin"
        echo -e "${GREEN}已将 $HOME/bin 加入 PATH，重开终端生效。${RESET}"
    fi
fi

install_im() {
    wget -q -O "$TARGET_DIR/im" https://raw.githubusercontent.com/immiskae/stream/main/install.sh
    chmod +x "$TARGET_DIR/im"
    echo -e "${GREEN}安装完成！以后输入 im 即可启动菜单。${RESET}"
}

install_dependencies() {
    echo -e "${GREEN}正在安装必要依赖...${RESET}"
    if command -v apt >/dev/null 2>&1; then
        apt update -y && apt install -y curl wget unzip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl wget unzip
    else
        echo -e "${RED}不支持的系统，需手动安装 curl wget unzip${RESET}"
    fi
}


enable_bbr() {
    # 检测是否是 LXC 环境
    if grep -qaE 'lxc|container' /proc/1/environ 2>/dev/null || grep -qaE 'lxc|container' /proc/1/cgroup 2>/dev/null; then
        echo -e "${YELLOW}⚠️ 检测到当前环境为 LXC 容器，不支持该BBR + TCP 优化！${RESET}"
        echo -e "${GRAY}此功能仅适用于独立服务器或完整虚拟机环境。${RESET}"
        echo
        return
    fi
    echo -e "${GREEN}正在开启 BBR 并覆盖写入优化参数...${RESET}"

    # 先备份原始配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # 覆盖写入优化内容
    cat > /etc/sysctl.conf <<EOF
# ===== Miskae BBR + TCP 优化参数 =====
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_ecn = 0

net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 250000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 2000
net.core.dev_weight = 1024
net.core.dev_weight_tx_bias = 2
net.core.optmem_max = 81920

net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072

net.core.busy_poll = 100
net.core.busy_read = 100

net.ipv4.ip_local_port_range = 1024 65535

fs.file-max = 16777216
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
# ===== End Miskae =====
EOF

    # 立即生效
    sysctl -p

    echo -e "${GREEN}BBR 和 TCP 网络参数已覆盖写入并生效！${RESET}"
    sleep 2
    exit 0
}


install_3-xui(){
    clear
    echo -e "${GREEN}正在安装 3X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    sleep 2
    exit 0
}

install_xui() {
    clear
    echo -e "${GREEN}正在安装 X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    sleep 2
    exit 0
}

install_s-ui() {
    clear
    echo -e "${GREEN}正在安装 S-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
    sleep 2
    exit 0
}

manage_clean(){
    clear
    echo -e "${GREEN}正在安装 S-UI 面板...${RESET}"
    bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/debian-safe/main/clean.sh)
    sleep 2
}

install_mtr(){
    clear
    echo -e "${GREEN}💫 MTR 自动报告...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/hiapb/auto-mtr/main/install.sh)
    sleep 2
    exit 0
}


uninstall_im() {
    echo -e "${RED}正在卸载 im 管理脚本...${RESET}"
    rm -f "$TARGET_DIR/im"
    echo -e "${GREEN}Miskae 管理脚本已卸载！${RESET}"
    exit 0
}

show_menu() {
    clear
    echo -e "${GREEN}=== Miskae 一键管理脚本 ===${RESET}"
    echo -e "${GREEN}=== 转发面板地址:im.miskae.cc ===${RESET}"
    echo "----------------------------------"
    echo "1) 安装 X-UI 面板"
    echo "2) 安装 3X-UI 面板"
    echo "3) 安装 S-UI 面板"
    echo "4) 开启 BBR 并优化 TCP 设置"
    echo "5) 🧹一键深度清理"
    echo "6) 💫 MTR 自动报告"
    echo "0) 卸载 Miskae 管理脚本"
    echo "q) 退出"
    echo "----------------------------------"
    read -p "请选择操作: " choice
    case "$choice" in
        1)  install_xui ;;
        2)  install_3-xui ;;
        3)  install_s-ui ;;
        4)  enable_bbr ;;
        5)  manage_clean ;;
        6)  install_mtr ;;
        0)  uninstall_im ;;
        q)  exit 0 ;;
        *)  echo -e "${RED}无效选项！${RESET}"; sleep 2; exit 1 ;;
    esac
}

if [[ "$0" != "$TARGET_DIR/im" ]]; then
    install_im
    echo -e "${GREEN}立即为你启动菜单面板...${RESET}"
    sleep 1
    exec "$TARGET_DIR/im"
    exit 0
else
    show_menu
fi
