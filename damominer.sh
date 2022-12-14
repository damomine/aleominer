#!/usr/bin/env bash

# 变量
SHELL_VERSION="0.9.9"
DAMOMINER_DIR="${HOME}/.damominer"
DAMOMINER_CONF_FILE="${DAMOMINER_DIR}/damominer.conf"
DAMOMINER_LOG_FILE="${DAMOMINER_DIR}/aleo.log"
DAMOMINER_FILE="${DAMOMINER_DIR}/damominer"
DAMOMINER_PROXIES=( "aleo1.damominer.hk:9090" "aleo2.damominer.hk:9090" "aleo3.damominer.hk:9090" "asiahk.damominer.hk:9090" )
NVIDIA_DOWNLOAD_BASE_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64"

# 字体颜色配置
Yellow="\033[33m"
Green="\033[32m"
Red="\033[31m"
Blue="\033[36m"
Font="\033[0m"

# 提示
INFO="[${Green}Info${Font}]"
ERROR="[${Red}Error${Font}]"
TIP="[${Green}Tip${Font}]"

yellow(){
    echo -e "${Yellow} $1 ${Font}"
}

green(){
    echo -e "${Green} $1 ${Font}"
}

red(){
    echo -e "${Red} $1 ${Font}"
}

blue(){
    echo -e "${Blue} $1 ${Font}"
}

check_root() {
    [[ $EUID != 0 ]] && echo -e "${ERROR} 当前非 root 账号, 无法继续操作. 请更换 root 账号或使用 ${Blue}sudo su${Font} 命令获取临时 root 权限 (执行后可能会提示输入当前账号的密码)." && exit 1
}

check_ubuntu() {
  OS=$(cat /etc/lsb-release | grep -oP '(?<=DISTRIB_ID=)[^ ]*')

  # fail on non-zero return value
  if [ ! $OS = "Ubuntu" ]; then
      echo -e "${ERROR} 管理脚本只支持 ubuntu 系统"
      exit 1
  fi
}

update_shell() {
    echo -e "${INFO} 管理脚本当前版本为 [ ${SHELL_VERSION} ], 开始检测最新版本..."
    SHELL_NEW_VERSION=$(
        {
            wget -t2 -T3 -qO- "https://ghproxy.com/https://raw.githubusercontent.com/damomine/aleominer/master/damominer.sh" ||
            wget -t2 -T3 -qO- "https://raw.githubusercontent.com/damomine/aleominer/master/damominer.sh" ||
            wget -t2 -T3 -qO- "https://proxy.jeongen.com/https://raw.githubusercontent.com/damomine/aleominer/master/damominer.sh"
        } | grep 'SHELL_VERSION="' | awk -F "=" '{print $NF}' | sed 's/\"//g' | head -1
    )

    [[ -z ${SHELL_NEW_VERSION} ]] && echo -e "${ERROR} 无法连接到 Github, 检测最新版本失败!" && exit 0

    if [[ ${SHELL_NEW_VERSION} != ${SHELL_VERSION} ]]; then
		echo -e "发现新版本[ ${SHELL_NEW_VERSION} ], 是否更新？[Y/n]"
		read -p "(默认: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
            if [[ -e "/etc/init.d/damominer" ]]; then
                uninstall_service
                install_damominer
                restart_damominer
            fi

			wget -N -t2 -T3 "https://ghproxy.com/https://raw.githubusercontent.com/damomine/aleominer/master/damominer.sh" -O damominer.sh ||
            wget -N -t2 -T3 "https://raw.githubusercontent.com/damomine/aleominer/master/damominer.sh" -O damominer.sh ||
            wget -N -t2 -T3 "https://proxy.jeongen.com/https://raw.githubusercontent.com/damomine/aleominer/master/damominer.sh" -O damominer.sh

            chmod +x damominer.sh

            echo -e "${INFO} 管理脚本已更新为最新版本[ ${SHELL_NEW_VERSION} ]!" && exit 0
		else
			echo && echo "${INFO} 已取消..." && echo
		fi
	else
		echo -e "${INFO} 当前已是最新版本[ ${SHELL_NEW_VERSION} ]!"
	fi
}

check_damominer_file() {
    if [ ! -f ${DAMOMINER_FILE} ];then
        echo -e "${ERROR} Damominer 没有安装, 请检查!"
        exit 1
    fi
}

check_damominer_conf_file() {
    if [ ! -f ${DAMOMINER_CONF_FILE} ];then
        echo -e "${ERROR} Damominer 配置文件不存在, 请检查!"
        exit 1
    fi
}

check_installed_status() {
    check_damominer_file
    check_damominer_conf_file
}

check_pid() {
    PID=$(ps -ef | grep "damominer" | grep -v grep | grep -v "damominer.sh" | grep -v "init.d" | awk '{print $2}')
}

check_running() {
	check_pid
	if [[ ! -z ${PID} ]]; then
		return 0
	else
		return 1
	fi
}

check_version() {
    if [ -f ${DAMOMINER_FILE} ];then
        DAMOMINER_VERSION=$(${DAMOMINER_FILE} -V | awk '{print $2}')
    fi
}

check_new_version() {
    check_version
    if [[ ! -z ${DAMOMINER_VERSION} ]];then
        echo -e "${INFO} Damominer 当前版本为 [ v${DAMOMINER_VERSION} ], 开始检测最新版本..."
    else
        echo -e "${INFO} 开始检测 Damominer 最新版本..."
    fi
    
    DAMOMINER_NEW_VERSION=$(
        {
            wget -t2 -T3 -qO- "https://api.github.com/repos/damomine/aleominer/releases/latest" ||
            wget -t2 -T3 -qO- "https://proxy.jeongen.com/https://api.github.com/repos/damomine/aleominer/releases/latest" ||
            wget -t2 -T3 -qO- "https://gh-api.p3terx.com/repos/damomine/aleominer/releases/latest"
        } | grep -o '"tag_name": ".*"' | head -n 1 | cut -d'"' -f4
    )
    if [[ -z ${DAMOMINER_NEW_VERSION} ]]; then
        echo -e "${ERROR} Damominer 最新版本获取失败, 请手动获取最新版本号[ https://github.com/damomine/aleominer/releases ]"
        read -e -p "请输入版本号:" DAMOMINER_NEW_VERSION
        [[ -z "${DAMOMINER_NEW_VERSION}" ]] && echo "${INFO} 取消..." && exit 1
    fi

    echo -e "${INFO} Damominer 最新版本为 [ ${DAMOMINER_NEW_VERSION} ]"
}

download_damominer() {
    if [ -z ${DAMOMINER_NEW_VERSION} ];then
        echo -e "${ERROR} Damominer 版本获取失败, 中断下载"
    fi
    echo -e "${INFO} 开始下载 Damominer 版本 ${DAMOMINER_NEW_VERSION}..."

    DOWNLOAD_URL="https://github.com/damomine/aleominer/releases/download/${DAMOMINER_NEW_VERSION}/damominer_linux_${DAMOMINER_NEW_VERSION}.tar"
    
    wget -N -t2 -T3 "https://ghproxy.com/${DOWNLOAD_URL}" -O damominer_linux_${DAMOMINER_NEW_VERSION}.tar ||
        wget -N -t2 -T3 "${DOWNLOAD_URL}" -O damominer_linux_${DAMOMINER_NEW_VERSION}.tar ||
        wget -N -t2 -T3 "https://proxy.jeongen.com/${DOWNLOAD_URL}" -O damominer_linux_${DAMOMINER_NEW_VERSION}.tar

    [[ ! -s "damominer_linux_${DAMOMINER_NEW_VERSION}.tar" ]] && echo -e "${Error} Damominer 下载失败!" && exit 1
    echo -e "${INFO} 下载 Damominer 版本 ${DAMOMINER_NEW_VERSION}成功!"
    tar -xvf damominer_linux_${DAMOMINER_NEW_VERSION}.tar || (echo -e "${ERROR} 解压 damominer_linux_${DAMOMINER_NEW_VERSION}.tar 失败!" && rm damominer_linux_${DAMOMINER_NEW_VERSION}.tar && exit 1)
    
    [[ ! -s "damominer" ]] && echo -e "${Error} Damominer 主程序不存在!" && exit 1
    if [ ! -d "${DAMOMINER_DIR}" ];then
        bash -c "mkdir ${DAMOMINER_DIR}"
    fi
    while [[ -f ${DAMOMINER_FILE} ]]; do
        echo -e "${INFO} 删除旧版 Damominer 二进制文件..."
        rm -vf "${DAMOMINER_FILE}"
    done
    bash -c "mv -f damominer ${DAMOMINER_FILE}"
    [[ ! -f ${DAMOMINER_FILE} ]] && echo -e "${Error} Damominer 主程序安装失败!" && exit 1
    chmod 755 ${DAMOMINER_FILE}
    echo -e "${INFO} Damominer 主程序安装完成 (${Blue}${DAMOMINER_FILE}${Font})"
}

install_damominer() {
    check_root
    [[ -f ${DAMOMINER_FILE} ]] && echo -e "${ERROR} Damominer 已安装, 请检查!" && exit 1
    
    echo -e "${INFO} 开始检测依赖..."
    repair_openssl
    add_dns

    echo -e "是否要安装 NVIDIA 显卡驱动? [Y/n]"
    read -p "(默认: y):" INSTALL_NVIDIA
    INSTALL_NVIDIA="${INSTALL_NVIDIA:=Y}"

    if [[ $INSTALL_NVIDIA = "Y" ]] || [[ $INSTALL_NVIDIA = "y" ]]; then
        install_nvidia
    fi
    
    do_install_damominer

    echo -e "${INFO} 开始启动 Damominer..."
    start_damominer
}

do_install_damominer() {
    echo -e "${INFO} 开始安装 Damominer..."
    check_new_version
    download_damominer
    generate_config
    install_service
    echo -e "${INFO} Damominer 安装成功完成!"
}

uninstall_damominer() {
    check_root
    echo -e "确定要卸载 Damominer? [Y/n]:"
    read -p "(默认: y):" UNINSTALL
    UNINSTALL="${UNINSTALL:=Y}"
    if [[ $UNINSTALL = "Y" ]] || [[ $UNINSTALL = "y" ]]; then
        echo && do_uninstall_damominer && echo
    else
        echo && echo -e "${INFO} 卸载已取消..." && echo
    fi
}

do_uninstall_damominer() {
    echo -e "${INFO} 开始卸载 Damominer..."
    [[ -s /etc/init.d/damominer ]] && /etc/init.d/damominer stop echo -e "${INFO} 停止运行 Damoiner 成功!"
    check_pid
    [[ ! -z $PID ]] && kill -9 ${PID} && echo -e "${INFO} 关闭 Damoiner 进程成功!"
    restore_dns
    [[ -f ${DAMOMINER_FILE} ]] && rm -f ${DAMOMINER_FILE} && echo -e "${INFO} 删除 Damoiner 主程序成功!"
    uninstall_service
    [[ -e ${DAMOMINER_LOG_FILE} ]] && rm -f ${DAMOMINER_LOG_FILE} && echo -e "${INFO} 删除 Damoiner 日志文件成功!"
    echo -e "${INFO} Damominer 卸载完成!"
}

update_damominer() {
    check_root
    echo -e "${INFO} 开始更新 Damominer..."

    check_installed_status
    check_new_version

    if [ "v${DAMOMINER_VERSION}" == "${DAMOMINER_NEW_VERSION}" ]; then
        echo -e "${INFO} Damominer 已经为最新版本!"
    fi

    echo -e "确定要更新 Damominer 版本 [v${DAMOMINER_VERSION}] 到远程版本 [${DAMOMINER_NEW_VERSION}]? [Y/n]:"
    read -p "(默认: y):" UPDATE
    UPDATE="${UPDATE:=Y}"
    if [[ $UPDATE = "Y" ]] || [[ $UPDATE = "y" ]]; then

        do_uninstall_damominer
        do_install_damominer

        echo -e "${INFO} Damominer 更新完成!"
        echo -e "${INFO} 开始启动 Damominer..."
        start_damominer
    else
        echo && echo -e "${INFO} 更新已取消..." && echo
    fi
}

install_service() {
    echo -e "${INFO} 安装 Damominer 启动脚本..."
    wget -N -t2 -T3 "https://raw.githubusercontent.com/damomine/aleominer/master/damominer" -O /etc/init.d/damominer ||
        wget -N -t2 -T3 "https://ghproxy.com/https://raw.githubusercontent.com/damomine/aleominer/master/damominer" -O /etc/init.d/damominer ||
        wget -N -t2 -T3 "https://proxy.jeongen.com/https://raw.githubusercontent.com/damomine/aleominer/master/damominer" -O /etc/init.d/damominer
    [[ ! -s /etc/init.d/damominer ]] && {
        echo -e "${ERROR} Damominer 启动脚本下载失败!"
        [[ -f /etc/init.d/damominer ]] && rm /etc/init.d/damominer
        exit 1
    }
    chmod 755 /etc/init.d/damominer
    update-rc.d -f damominer defaults 99
    echo -e "${INFO} Damominer 启动脚本安装完成!"
}

uninstall_service() {
    echo -e "${INFO} 卸载 Damominer 启动脚本..."
    update-rc.d -f damominer remove
    rm -rf "/etc/init.d/damominer"
    echo -e "${INFO} 卸载 Damominer 启动脚本成功!"
}

generate_config() {
    echo -e "${INFO} 开始初始化配置文件..."
    if [[ ! -e ${DAMOMINER_CONF_FILE} ]]; then
        echo -e "# 指定 Aleo 地址
# 注意：使用你自己的地址作为挖矿地址
address=aleo1mf6km7m04mj2s86t5xwe6gmhaav3eucaxfmrpemg0edajqntnsxqx85qjp

# 指定 Damominer 代理地址 
# 注意：选择连接状况最优的代理地址, 延时掉线率高会导致爆块低
proxy=aleo3.damominer.hk:9090

# 指定设备名称
# 注意: 设备名称由数字和字母组成, 并且不能超过15个字符长度
# worker=

# 指定运行的显卡, 多个值之间使用逗号(,)分隔, 例如 0,1,2
# 注意: 如果没有指定将使用所有卡
# gpu=" > ${DAMOMINER_CONF_FILE}
        echo -e "${INFO} Damominer 配置文件创建成功 (${Blue}${DAMOMINER_CONF_FILE}${Font})!"

        configure_address
        configure_proxy_with_fastest
    else
        echo -e "${INFO} Damominer 配置文件已存在 (${Blue}${DAMOMINER_CONF_FILE}${Font})"
    fi
}

read_config() {
    if [[ ! -e ${DAMOMINER_CONF_FILE} ]]; then
       echo -e "${Error} Damominer 配置文件不存在!" && exit 1
    else
        ADDRESS=$(cat ${DAMOMINER_CONF_FILE} | grep "^address=" | awk -F "=" '{print $NF}')
        PROXY=$(cat ${DAMOMINER_CONF_FILE} | grep "^proxy=" | awk -F "=" '{print $NF}')
        WORKER=$(cat ${DAMOMINER_CONF_FILE} | grep "^worker=" | awk -F "=" '{print $NF}')
        GPU=$(cat ${DAMOMINER_CONF_FILE} | grep "^gpu=" | awk -F "=" '{print $NF}')
    fi
}

view_config() {
    read_config
	clear
	echo -e "\n ${Red}————————————— Damominer 配置信息 —————————————${Font} 
 Aleo 地址\t: ${Yellow}${ADDRESS}${Font}
 代理地址\t: ${Yellow}${PROXY}${Font}
 设备名称\t: ${Yellow}${WORKER}${Font}
 运行显卡\t: ${Yellow}${GPU}${Font}"
}

new_account() {
    check_damominer_file
    
    NEW_ACCOUNT_OUTPUT="$(${DAMOMINER_FILE} --new-account)"
    echo -e "\n ${Red}————————————————— 请自己保管好以下这段内容 ——————————————————${Font} "
    echo -e "${NEW_ACCOUNT_OUTPUT}"
    echo -e "\n ${Red}————————————— 本脚本没有保存, 丢失将无法领取奖励 —————————————${Font} "
    echo
    echo -e "${INFO} Aleo 钱包地址已经生成!"
    echo
    echo -e "是否要更新钱包地址到配置文件? [Y/n]"
    read -p "(默认: y):" PURGE
    PURGE="${PURGE:=Y}"

    if [[ $PURGE = "Y" ]] || [[ $PURGE = "y" ]]; then
        check_damominer_conf_file
        NEW_ADDRESS=$(echo "${NEW_ACCOUNT_OUTPUT}" | grep -v '#' | grep 'Address: ' | awk '{print $2}')

        sed -i 's/^#\s*address=/address=/g' ${DAMOMINER_CONF_FILE} && sleep 1 && read_config
        sed -i 's/^address='${ADDRESS}'/address='${NEW_ADDRESS}'/g' ${DAMOMINER_CONF_FILE}

        if ! grep -wq "address=${NEW_ADDRESS}" ${DAMOMINER_CONF_FILE}; then 
            echo -e "address=${NEW_ADDRESS}" >>${DAMOMINER_CONF_FILE}
        fi
        if [[ $? -eq 0 ]]; then
            echo -e "${INFO} Damominer 钱包地址修改成功! 新钱包地址为：${Green}${NEW_ADDRESS}${Font}"
            
            check_running
            # if [[ ${CONFIGURE_ONLY} != "1" ]]; then
	        if [[ $? -eq 0 ]]; then
                restart_damominer
            fi
        else
            echo -e "${ERROR} Damominer 钱包地址修改失败! 旧钱包地址为：${Green}${ADDRESS}${Font}"
        fi
    fi
}

start_damominer() {
    check_installed_status
    check_pid
    [[ ! -z ${PID} ]] && echo -e "${ERROR} Damominer 正在运行, 请检查!" && exit 1
    /etc/init.d/damominer start
    view_damominer_log
}

stop_damominer() {
    check_installed_status
    check_pid
    [[ -z ${PID} ]] && echo -e "${ERROR} Damominer 没有运行, 请检查!" && exit 1
    /etc/init.d/damominer stop
}

restart_damominer() {
    echo -e "${INFO} 重启 Damominer..."
    check_installed_status
    /etc/init.d/damominer restart
    view_damominer_log
}

configure_address() {
    echo -e "${INFO} 修改 Damominer 钱包地址..."
    
    check_damominer_conf_file

    CONFIGURE_ONLY=$1
    read_config
    if [[ -z "${ADDRESS}" ]]; then
        echo -e "当前没有配置 Damominer 钱包地址"
    else
        echo -e "当前 Damominer 钱包地址为: ${Green}${ADDRESS}${Font}"
    fi
    PS3="请选择 Damominer 钱包地址设置方式:"
    options=("手动输入" "生成新钱包" )
    select opt in "${options[@]}"
    do
        case $opt in
            "手动输入")
                read -e -p " 请输入新的 Damominer 钱包地址: " NEW_ADDRESS
                echo
                break
                ;;
            "生成新钱包")
                check_damominer_file
                NEW_ACCOUNT_OUTPUT="$(${DAMOMINER_FILE} --new-account)"
                echo -e "\n ${Red}——————————————————— 请自己保管好以下这段内容 ————————————————————${Font} "
                echo -e "${NEW_ACCOUNT_OUTPUT}"
                echo -e "\n ${Red}————— 本脚本没有保存, 丢失将无法领取奖励, 没有任何途径可以找回 —————${Font} "
                echo
                echo -e "${INFO} Aleo 钱包地址已经生成!"

                NEW_ADDRESS=$(echo "${NEW_ACCOUNT_OUTPUT}" | grep -v '#' | grep 'Address: ' | awk '{print $2}')
                break
                ;;
            *) echo "无效选项";;
        esac
    done

    [[ -z "${NEW_ADDRESS}" ]] && NEW_ADDRESS=${ADDRESS}
    if [[ "${ADDRESS}" != "${NEW_ADDRESS}" ]]; then
        sed -i 's/^#\s*address=/address=/g' ${DAMOMINER_CONF_FILE} && sleep 1 && read_config
        sed -i 's/^address='${ADDRESS}'/address='${NEW_ADDRESS}'/g' ${DAMOMINER_CONF_FILE}

        if ! grep -wq "address=${NEW_ADDRESS}" ${DAMOMINER_CONF_FILE}; then 
            echo -e "address=${NEW_ADDRESS}" >>${DAMOMINER_CONF_FILE}
        fi
        if [[ $? -eq 0 ]]; then
            echo -e "${INFO} Damominer 钱包地址修改成功! 新钱包地址为：${Green}${NEW_ADDRESS}${Font}"
            
            check_running
            # if [[ ${CONFIGURE_ONLY} != "1" ]]; then
	        if [[ $? -eq 0 ]]; then
                restart_damominer
            fi
        else
            echo -e "${ERROR} Damominer 钱包地址修改失败! 旧钱包地址为：${Green}${ADDRESS}${Font}"
        fi
    else
        echo -e "${INFO} 与旧配置一致, 无需修改"
    fi
}

configure_proxy() {
    echo -e "${INFO} 修改 Damominer 代理地址..."

    check_damominer_conf_file

    CONFIGURE_ONLY=$1
    read_config
    if [[ -z "${PROXY}" ]]; then
        echo -e "当前没有配置 Damominer 代理地址"
    else
        echo -e "当前 Damominer 代理地址为: ${Green}${PROXY}${Font}"
    fi

    PS3="请选择 Damominer 代理地址设置方式:"
    options=("自动选择" "列表选择" "手动输入")
    select opt in "${options[@]}"
    do
        case $opt in
            "自动选择")
                get_fastest_proxy
                echo -e "${INFO} 自动选择最快代理 ${fast_proxy}"
                NEW_PROXY=${fast_proxy}
                break
                ;;
            "列表选择")
                PS3="请选择 Damominer 代理地址:"
                select proxy in "${DAMOMINER_PROXIES[@]}"
                do
                    NEW_PROXY=${proxy}
                    break
                done
                break
                ;;
            "手动输入")
                read -e -p " 请输入新的 Damominer 代理地址: " NEW_PROXY
                echo
                break
                ;;
            *) echo "无效选项";;
        esac
    done

    [[ -z "${NEW_PROXY}" ]] && NEW_PROXY=${PROXY}
    if [[ "${PROXY}" != "${NEW_PROXY}" ]]; then
        sed -i 's/^#\s*proxy=/proxy=/g' ${DAMOMINER_CONF_FILE} && sleep 1 && read_config
        sed -i 's/^proxy='${PROXY}'/proxy='${NEW_PROXY}'/g' ${DAMOMINER_CONF_FILE}

        if ! grep -wq "proxy=${NEW_PROXY}" ${DAMOMINER_CONF_FILE}; then 
            echo -e "proxy=${NEW_PROXY}" >>${DAMOMINER_CONF_FILE}
        fi
        if [[ $? -eq 0 ]]; then
            echo -e "${INFO} Damominer 代理地址修改成功! 新代理地址为：${Green}${NEW_PROXY}${Font}"
            
            check_running
            # if [[ ${CONFIGURE_ONLY} != "1" ]]; then
	        if [[ $? -eq 0 ]]; then
                restart_damominer
            fi
        else
            echo -e "${ERROR} Damominer 代理地址修改失败! 旧代理地址为：${Green}${PROXY}${Font}"
        fi
    else
        echo -e "${INFO} 与旧配置一致, 无需修改"
    fi
}

configure_proxy_with_fastest() {
    get_fastest_proxy
    echo -e "${INFO} 自动设置为最快代理 ${fast_proxy}"
    NEW_PROXY=${fast_proxy}

    sed -i 's/^#\s*proxy=/proxy=/g' ${DAMOMINER_CONF_FILE} && sleep 1 && read_config
    sed -i 's/^proxy='${PROXY}'/proxy='${NEW_PROXY}'/g' ${DAMOMINER_CONF_FILE}

    if ! grep -wq "proxy=${NEW_PROXY}" ${DAMOMINER_CONF_FILE}; then 
        echo -e "proxy=${NEW_PROXY}" >>${DAMOMINER_CONF_FILE}
    fi

     if [[ $? -eq 0 ]]; then
        echo -e "${INFO} Damominer 代理地址修改成功!"
        
        check_running
        # if [[ ${CONFIGURE_ONLY} != "1" ]]; then
        if [[ $? -eq 0 ]]; then
            restart_damominer
        fi
    else
        echo -e "${ERROR} Damominer 代理地址修改失败!"
    fi
}

get_fastest_proxy() {
    echo -e "${INFO} 测试所有代理线路..."
    for proxy in "${DAMOMINER_PROXIES[@]}"
    do
        url=$(echo ${proxy} | cut -d ":" -f 1)
        if ping -c 1 $url | grep -o "time=.*" >> /dev/null 2>&1; then 
            time_str=$(ping -c 1 $url 2>/dev/null | grep -o "time=.*" | cut -d "=" -f 2 | awk '{printf $1}');
            ping_time=${time_str//[^0-9]/}

            if [ ! $ping_time ]; then 
                continue;
            fi
        
            case $ping_time in
                ''|*[!0-9]*)
                    # ping_time 不是有效的数字
                    echo "$proxy : Error"
                    ;;
                *)
                    if [ ! $fast_ping_time ]; then 
                        fast_ping_time=$ping_time;
                        fast_proxy=$proxy;
                    fi
                    echo "$proxy : $time_str ms"

                    # If time is less than previous pings, store the url & time
                    if [ "$ping_time" -lt "$fast_ping_time" ]; then
                        fast_proxy=$proxy
                        fast_ping_time=$ping_time
                    fi
                    ;;
            esac
        fi
    done
}

configure_worker() {
    echo -e "${INFO} 修改 Damominer 设备名称..."

    check_damominer_conf_file

    CONFIGURE_ONLY=$1
    read_config

    if [[ -z "${WORKER}" ]]; then
        echo -e "当前没有配置 Damominer 设备名称"
    else
        echo -e "当前 Damominer 设备名称为: ${Green}${WORKER}${Font}"
    fi
    read -e -p " 请输入新的 Damominer 设备名称 (限字母与数字字符): " NEW_WORKER
    echo
    if [[ "${WORKER}" != "${NEW_WORKER}" ]]; then
        sed -i 's/^#\s*worker=/worker=/g' ${DAMOMINER_CONF_FILE} && sleep 1 && read_config
        sed -i 's/^worker='${WORKER}'/worker='${NEW_WORKER}'/g' ${DAMOMINER_CONF_FILE}

        if ! grep -wq "worker=${NEW_WORKER}" ${DAMOMINER_CONF_FILE}; then 
            echo -e "worker=${NEW_WORKER}" >>${DAMOMINER_CONF_FILE}
        fi
        if [[ $? -eq 0 ]]; then
            echo -e "${INFO} Damominer 设备名称修改成功! 新设备名称为：${Green}${NEW_WORKER}${Font}"
            
            check_running
            # if [[ ${CONFIGURE_ONLY} != "1" ]]; then
	        if [[ $? -eq 0 ]]; then
                restart_damominer
            fi
        else
            echo -e "${ERROR} Damominer 设备名称修改失败! 旧设备名称为：${Green}${WORKER}${Font}"
        fi
    else
        echo -e "${INFO} 与旧配置一致, 无需修改"
    fi
}

configure_gpu() {
    echo -e "${INFO} 修改 Damominer 运行显卡..."

    check_damominer_conf_file
    
    CONFIGURE_ONLY=$1
    read_config

    if [[ -z "${GPU}" ]]; then
        echo -e "当前没有配置 Damominer 运行显卡"
    else
        echo -e "当前 Damominer 运行显卡为: ${Green}${GPU}${Font}"
    fi
    
    read -e -p " 请输入新的 Damominer 运行显卡 (没有输入将使用所有显卡, 多张显卡使用逗号 "," 分隔, 例如 "0,1,2"): " NEW_GPU
    echo
    if [[ "${GPU}" != "${NEW_GPU}" ]]; then
        sed -i 's/^#\s*gpu=/gpu=/g' ${DAMOMINER_CONF_FILE} && sleep 1 && read_config
        sed -i 's/^gpu='${GPU}'/gpu='${NEW_GPU}'/g' ${DAMOMINER_CONF_FILE}

        if ! grep -wq "gpu=${NEW_GPU}" ${DAMOMINER_CONF_FILE}; then 
            echo -e "gpu=${NEW_GPU}" >>${DAMOMINER_CONF_FILE}
        fi
        if [[ $? -eq 0 ]]; then
            echo -e "${INFO} Damominer 运行显卡修改成功! 新运行显卡为：${Green}${NEW_GPU}${Font}"
            
            check_running
            # if [[ ${CONFIGURE_ONLY} != "1" ]]; then
	        if [[ $? -eq 0 ]]; then
                restart_damominer
            fi
        else
            echo -e "${ERROR} Damominer 运行显卡修改失败! 旧运行显卡为：${Green}${ADDRESS}${Font}"
        fi
    else
        echo -e "${INFO} 与旧配置一致, 无需修改"
    fi
}

configure_packages() {
    echo -e "${INFO} 更新软件源..."
    apt update
    echo -e "${INFO} 更新软件源成功!"

    echo -e "{Info} 升级软件包到最新版本? [Y/n]:"
    read -p "(默认: y):" UPGRADE
    UPGRADE="${UPGRADE:=Y}"
    if [[ $UPGRADE = "Y" ]] || [[ $UPGRADE = "y" ]]; then
        apt-get upgrade -y
        echo -e "${INFO} 升级软件包到最新版本成功!"
    fi
}

blacklist_nouveau() {
    echo -e "${INFO} 禁用 nouveau 驱动..."

    # Create Blacklist for Nouveau Driver
    if [ ! -f "/etc/modprobe.d/blacklist-nouveau.conf" ]; then
        touch "/etc/modprobe.d/blacklist-nouveau.conf"
    fi
    
    if [[ ! $(grep "^blacklist nouveau$" /etc/modprobe.d/blacklist-nouveau.conf) ]]; then
        echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nvidia-nouveau.conf 
    fi

    if [[ ! $(grep "^options nouveau modeset=0$" /etc/modprobe.d/blacklist-nouveau.conf) ]]; then
        echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
    fi

    # Update the kernel to reflect changes:
    update-initramfs -u
    echo -e "${INFO} 禁用 nouveau 驱动成功!"
}

install_nvidia() {
    echo -e "${INFO} 开始安装显卡驱动..."

    configure_packages

    echo -e "是否要卸载旧的显卡驱动（推荐卸载）? [Y/n]"
    read -p "(默认: y):" PURGE
    PURGE="${PURGE:=Y}"

    if [[ $PURGE = "Y" ]] || [[ $PURGE = "y" ]]; then
        purge_nvidia
    fi

    nvidia_install_types=( 'APT' 'NVIDIA' )
    PS3="选择显卡驱动的安装方式: "
    select nvidia_install_type in ${nvidia_install_types[@]}; do
        case ${nvidia_install_type} in
        'APT')
            perform_nvidia_apt_install
            break;
        ;;
        'NVIDIA')
            perform_nvidia_website_install
            break;
        ;;
        *)
            echo -e "${ERROR} 输入无效."
    esac
    done

    echo -e "${INFO} 安装显卡驱动完成! 如有报错请重启后再重新安装"
}

perform_nvidia_apt_install() {
    # add the repository for ubuntu-drivers and select recommended:
    apt install ubuntu-drivers-common -y

    echo -e "是否要自动安装推荐驱动? [Y/n]"
    read -p "(默认: y):" AUTO
    AUTO="${AUTO:=Y}"

    if [[ $AUTO = "Y" ]] || [[ $AUTO = "y" ]]; then
        ubuntu-drivers autoinstall
    elif [[ $AUTO = "N" ]] || [[ $AUTO = "n" ]]; then
        echo -e "请输入要安装的版本号, 新系列显卡使用 515, 525, 老系列显卡使用 470: "
        read -p "(默认: 525):" NVIDIA_APT_VERSION
        NVIDIA_APT_VERSION="${NVIDIA_APT_VERSION:=525}"
        apt install nvidia-driver-$NVIDIA_APT_VERSION -y

        blacklist_nouveau
    else
        echo -e "${ERROR} 输入无效, 请输入 Y 或者 N."
        echo -e "${ERROR} 安装显卡驱动中断."
        exit
    fi
}

perform_nvidia_website_install() {
    echo -e "是否要自动安装最新驱动? [Y/n]"
    read -p "(默认: y):" AUTO
    AUTO="${AUTO:=Y}"

    if [[ $AUTO = "Y" ]] || [[ $AUTO = "y" ]]; then
        NVIDIA_INSTALL_VERSION=$(wget -q -O - https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt | cut -d" " -f 1)
    elif [[ $AUTO = "N" ]] || [[ $AUTO = "n" ]]; then
        echo -e "请输入要安装的版本号, 新系列显卡使用 515.65.01, 525.60.11, 老系列显卡使用 470.141.03: "
        read -p "(默认: 525.60.11):" NVIDIA_INSTALL_VERSION
        NVIDIA_INSTALL_VERSION="${NVIDIA_INSTALL_VERSION:=525.60.11}"
    else
        echo -e "${ERROR} 输入无效, 请输入 Y 或者 N."
        echo -e "${ERROR} 安装显卡驱动中断."
        exit
    fi

    blacklist_nouveau

    rm -f "NVIDIA-Linux-x86_64-$NVIDIA_INSTALL_VERSION.run"
    wget $NVIDIA_DOWNLOAD_BASE_URL/$NVIDIA_INSTALL_VERSION/NVIDIA-Linux-x86_64-$NVIDIA_INSTALL_VERSION.run
    chmod +x NVIDIA-Linux-x86_64-$NVIDIA_INSTALL_VERSION.run

    # 执行参数说明
    # -q Quiet
    # -a Accept License
    # -n Suppress Questions
    # -s Disable ncurses interface
    ./NVIDIA-Linux-x86_64-$NVIDIA_INSTALL_VERSION.run -a -n -s

    # 清理下载的文件
    rm -f "NVIDIA-Linux-x86_64-$NVIDIA_INSTALL_VERSION.run"
}

purge_nvidia() {
    echo -e "${INFO} 开始卸载显卡驱动..."

    apt purge nvidia-* -y
    apt autoremove -y
    for i in $(dpkg -l | grep nvidia | awk {'print $2'}); do echo $i; apt-get --purge remove $i -y; done
    echo -e "${INFO} 卸载显卡驱动成功! 请在重启前一个安装显卡驱动"
}

add_dns() {
    echo -e "${INFO} 开始添加 DNS..."

    if [[ ! -f /etc/resolv.conf.backup ]]; then
        echo -e "${INFO} 备份 DNS 文件到  (${Blue}/etc/resolv.conf.backup)"
        cp -f /etc/resolv.conf /etc/resolv.conf.backup
    fi
    if [[ ! $(grep "^# added by damominer$" /etc/resolv.conf) ]]; then
        echo '# added by damominer' >> /etc/resolv.conf
    fi
    if [[ ! $(grep "^nameserver 8.8.8.8$" /etc/resolv.conf) ]]; then
        echo nameserver 8.8.8.8 >> /etc/resolv.conf
    fi
    if [[ ! $(grep "^nameserver 223.5.5.5$" /etc/resolv.conf) ]]; then
        echo nameserver 223.5.5.5 >> /etc/resolv.conf
    fi
    if [[ ! $(grep "^nameserver 119.29.29.29$" /etc/resolv.conf) ]]; then
        echo nameserver 119.29.29.29 >> /etc/resolv.conf
    fi
    if [[ ! $(grep "^nameserver 1.1.1.1$" /etc/resolv.conf) ]]; then
        echo nameserver 1.1.1.1 >> /etc/resolv.conf
    fi
    echo -e "${INFO} 添加 DNS 成功!"
}

restore_dns() {
    echo -e "${INFO} 开始还原 DNS..."

    if [[ -e /etc/resolv.conf.backup ]]; then
        cp -f /etc/resolv.conf.backup /etc/resolv.conf
        rm /etc/resolv.conf.backup
    fi
    echo -e "${INFO} 还原 DNS 成功!"
}

repair_openssl() {
    OPENSSL_VERSION=$(openssl version)

    if [[ $OPENSSL_VERSION =~ "1.1.1" ]]; then
        echo -e "${INFO} OpenSSL 版本正常!"
    else
        echo -e "${INFO} 开始安装 OpenSSL 1.1.1..."
        # 从 Impish builds 下载 openssl 二进制包

        wget -N -t2 -T3 "http://security.ubuntu.com/ubuntu/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2.16_amd64.deb" -O openssl_1.1.1f-1ubuntu2.16_amd64.deb ||
            wget -N -t2 -T3 "https://mirrors.ustc.edu.cn/ubuntu/pool/main/o/openssl/openssl_1.1.1f-1ubuntu2.16_amd64.deb" -O openssl_1.1.1f-1ubuntu2.16_amd64.deb
        wget -N -t2 -T3 "http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb" -O libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb ||
            wget -N -t2 -T3 "https://mirrors.ustc.edu.cn/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb" -O libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb
        wget -N -t2 -T3 "http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb" -O libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb ||
            wget -N -t2 -T3 "https://mirrors.ustc.edu.cn/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb" -O libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb

        # 安装下载的二进制包
        dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
        dpkg -i libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb
        dpkg -i openssl_1.1.1f-1ubuntu2.16_amd64.deb

        # 清理下载的文件
        rm openssl_1.1.1f-1ubuntu2.16_amd64.deb
        rm libssl-dev_1.1.1f-1ubuntu2.16_amd64.deb
        rm libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb

        echo -e "${INFO} 安装 OpenSSL 1.1.1 成功!"
    fi
}

view_damominer_log() {
    [[ ! -e ${DAMOMINER_LOG_FILE} ]] && echo -e "${ERROR} Damominer 日志文件不存在!" && exit 1
    echo && echo -e "${TIP} 按 ${RED}Ctrl+C${Font} 终止查看日志" && echo -e "如果需要查看完整日志内容, 请用 ${RED}cat ${damominer_log}${Font} 命令。" && echo
    tail -f ${DAMOMINER_LOG_FILE}
}

clean_damominer_log() {
    [[ ! -e ${DAMOMINER_LOG_FILE} ]] && echo -e "${ERROR} Damominer 日志文件不存在!" && exit 1
    echo > ${DAMOMINER_LOG_FILE}
    echo -e "${INFO} damominer 日志已清空!"
}

start_menu(){
    [[ -f ${DAMOMINER_CONF_FILE} ]] && read_config && check_pid
    [[ -f ${DAMOMINER_FILE} ]] && check_version

    clear
    green " ========================================== "
    green " Damominer 一键安装管理脚本 v${SHELL_VERSION} "
    green " 系统: ubuntu18.04+ (推荐 20.04 lts)        "
    green " 网站: https://damominer.hk                 "
    green " Telegram 讨论群: https://t.me/DamoMiner666 "
    green " ========================================== "
    echo
    red " ———————————————— 安装向导 ———————————————— "
    yellow " 1. 升级 管理脚本"
    if [[ ! -z ${DAMOMINER_VERSION} ]];then
        yellow " 2. 安装 Damominer (已安装: v${DAMOMINER_VERSION})"
    else
        yellow " 2. 安装 Damominer"
    fi
    yellow " 3. 更新 Damominer"
    yellow " 4. 卸载 Damominer"
    red " ———————————————— 程序执行 ———————————————— "
    if [[ ! -z ${PID} ]]; then
        yellow " 5. 启动 Damominer (运行中)"
    else
        yellow " 5. 启动 Damominer"
    fi
    yellow " 6. 停止 Damominer"
    yellow " 7. 重启 Damominer"
    red " ———————————————— 配置设定 ———————————————— "
    
    yellow " 8. 查看 Damominer 配置"
    if [[ -z ${ADDRESS} ]]; then
        yellow " 9. 修改 Damominer 钱包地址"
    else
        yellow " 9. 修改 Damominer 钱包地址 (${ADDRESS})"
    fi
    if [[ -z ${PROXY} ]]; then
        yellow " 10. 修改 Damominer 代理地址"
    else
        yellow " 10. 修改 Damominer 代理地址 (${PROXY})"
    fi
    if [[ -z ${WORKER} ]]; then
        yellow " 11. 修改 Damominer 设备名称"
    else
        yellow " 11. 修改 Damominer 设备名称 (${WORKER})"
    fi
    if [[ -z ${GPU} ]]; then
        yellow " 12. 修改 Damominer 运行显卡 (所有显卡)"
    else
        yellow " 12. 修改 Damominer 运行显卡 (${GPU})"
    fi
    red " ———————————————— 查看信息 ———————————————— "
    yellow " 13. 查看 Damominer 运行日志"
    yellow " 14. 清空 Damominer 运行日志"
    red " ———————————————— 其他选项 ———————————————— "

    if [ ! -e /proc/driver/nvidia/version ]; then
        yellow " 15. 安装 NVIDIA 驱动 (未安装)"
    else
        NVIDIA_VERSION=$(cat /proc/driver/nvidia/version | head -n 1 | awk '{ print $8 }')
        yellow " 15. 安装 NVIDIA 驱动 (v${NVIDIA_VERSION})"
    fi
    
    yellow " 16. 卸载 NVIDIA 驱动"
    if ! [ -x "$(command -v openssl)" ]; then
        yellow " 17. 修复 OpenSSL 版本 (未安装)"
    else
        OPENSSL_VERSION=$(openssl version | head -n 1 | awk '{ print $2 }')

        if [[ $OPENSSL_VERSION =~ "1.1.1" ]]; then
            yellow " 17. 修复 OpenSSL 版本 (v${OPENSSL_VERSION})"
        else
            yellow " 17. 修复 OpenSSL 版本 (v${OPENSSL_VERSION}, 需修复)"
        fi
    fi
    if [[ ! $(grep "^# added by damominer$" /etc/resolv.conf) ]]; then
        yellow " 18. 添加 DNS (未添加)"
    else
        yellow " 18. 添加 DNS (已添加)"
    fi
    yellow " 19. 还原 DNS"
    yellow " 20. 生成 Aleo 钱包"
    yellow " 0. 退出 管理脚本"
    red " —————————————————————————————————————————"
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    update_shell
    ;;
    2)
    install_damominer
    ;;
    3)
    update_damominer
    ;;
    4)
    uninstall_damominer
    ;;
    5)
    start_damominer
    ;;
    6)
    stop_damominer
    ;;
    7)
    restart_damominer
    ;;
    8)
    view_config
    ;;
    9)
    configure_address
    ;;
    10)
    configure_proxy
    ;;
    11)
    configure_worker
    ;;
    12)
    configure_gpu
    ;;
    13)
    view_damominer_log
    ;;
    14)
    clean_damominer_log
    ;;
    15)
    install_nvidia
    ;;
    16)
    purge_nvidia
    ;;
    17)
    repair_openssl
    ;;
    18)
    add_dns
    ;;
    19)
    restore_dns
    ;;
    20)
    new_account
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字 (0-20)"
    sleep 1s
    start_menu
    ;;
    esac
}
check_ubuntu
start_menu
