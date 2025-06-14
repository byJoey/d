#!/bin/bash

# Author: Joey
# Blog: joeyblog.net
# Feedback TG (Feedback Telegram): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By:
#   - https://github.com/eooce (老王)
# Version: 2.5.2.sh
# Modification: 
#   - Fixed syntax error in the main menu's default case.
#   - Integrated a keep-alive heartbeat script to run in the foreground after deployment.
#   - Updated Nezha config parser to support v0 and v1 command formats.
#   - Changed UUID generation to prioritize Python.
#   - Randomized ARGO_PORT for recommended installation (2000-65535).

# --- Color Definitions ---
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m' 
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE_BOLD='\033[1;37m' 
COLOR_RESET='\033[0m' # No Color

# --- Helper Functions ---
print_separator() {
  echo -e "${COLOR_BLUE}======================================================================${COLOR_RESET}"
}

print_header() {
  local header_text="$1"
  local color_code="$2"
  if [ -z "$color_code" ]; then
    color_code="${COLOR_WHITE_BOLD}" # Default header color
  fi
  print_separator
  echo -e "${color_code}${header_text}${COLOR_RESET}"
  print_separator
}

# --- Keep-Alive Heartbeat Function ---
start_keepalive_heartbeat() {
    # --- 用户配置 ---
    local TARGET_DIR="bash_created_files" # 1. 设置文件存放的目录 (脚本会自动创建)
    local INTERVAL=30                      # 2. 每隔多少秒创建一个文件
    local MAX_FILES=30                     # 3. 当文件数量达到或超过这个值时，清空目录
    # --- 配置结束 ---

    mkdir -p "$TARGET_DIR"
    print_header "部署完成，保活程序已在前台启动" "${COLOR_GREEN}"
    echo -e "${COLOR_CYAN}日志目录: $(pwd)/${TARGET_DIR}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}按 CTRL+C 停止脚本。${COLOR_RESET}"
    print_separator

    while true; do
        # 检查并统计文件数量
        local file_count=$(find "$TARGET_DIR" -maxdepth 1 -type f | wc -l)

        # 判断是否需要删除文件
        if [ "$file_count" -ge "$MAX_FILES" ]; then
            rm -f "${TARGET_DIR}"/*
            # 清空后重新计数
            file_count=0
        fi

        # 创建新文件并写入时间
        local timestamp_for_filename=$(date +'%Y-%m-%d_%H-%M-%S')
        local new_file_path="${TARGET_DIR}/log_${timestamp_for_filename}.txt"
        echo "File created at: $(date +'%Y-%m-%d %H:%M:%S')" > "$new_file_path"

        # 打印简化的心跳和计数信息
        echo -e "${COLOR_GREEN}保活心跳 | 当前文件数: ${file_count}/${MAX_FILES}${COLOR_RESET}"

        # 等待指定的时间间隔
        sleep "$INTERVAL"
    done
}


# --- Welcome Message ---
print_header "欢迎使用 IBM-sb-ws 增强配置脚本" "${COLOR_GREEN}" 
echo -e "${COLOR_GREEN}  此脚本由 ${COLOR_WHITE_BOLD}Joey (joeyblog.net)${COLOR_GREEN} 维护和增强。${COLOR_RESET}"
echo -e "${COLOR_GREEN}  核心功能由 ${COLOR_WHITE_BOLD}老王 (github.com/eooce)${COLOR_GREEN} 实现。${COLOR_RESET}"
echo
echo -e "${COLOR_GREEN}  如果您对 ${COLOR_WHITE_BOLD}此增强脚本${COLOR_GREEN} 有任何反馈，请通过 Telegram 联系 Joey:${COLOR_RESET}"
echo -e "${COLOR_GREEN}    Joey's Feedback TG: ${COLOR_WHITE_BOLD}https://t.me/+ft-zI76oovgwNmRh${COLOR_RESET}"
print_separator
echo -e "${COLOR_GREEN}>>> 小白用户建议直接一路回车，使用默认配置快速完成部署 <<<${COLOR_RESET}" 
echo

# --- 读取用户输入的函数 ---
read_input() {
  local prompt_text="$1"
  local variable_name="$2"
  local default_value="$3"
  local advice_text="$4"

  if [ -n "$advice_text" ]; then
    echo -e "${COLOR_CYAN}  ${advice_text}${COLOR_RESET}" 
  fi

  if [ -n "$default_value" ]; then
    read -p "$(echo -e ${COLOR_YELLOW}"[?] ${prompt_text} [${default_value}]: "${COLOR_RESET})" user_input 
    eval "$variable_name=\"${user_input:-$default_value}\""
  else 
    local current_var_value=$(eval echo \$$variable_name)
    if [ -n "$current_var_value" ]; then
        read -p "$(echo -e ${COLOR_YELLOW}"[?] ${prompt_text} [${current_var_value}]: "${COLOR_RESET})" user_input
        eval "$variable_name=\"${user_input:-$current_var_value}\""
    else
        read -p "$(echo -e ${COLOR_YELLOW}"[?] ${prompt_text}: "${COLOR_RESET})" user_input
        eval "$variable_name=\"$user_input\""
    fi
  fi
  echo 
}

# --- 初始化变量 ---
CUSTOM_UUID=""
NEZHA_SERVER="" 
NEZHA_PORT=""   
NEZHA_KEY=""    
ARGO_DOMAIN=""  
ARGO_AUTH=""    
NAME="" 
CFIP="cloudflare.182682.xyz" 
CFPORT="443" 
CHAT_ID=""      
BOT_TOKEN=""    
UPLOAD_URL=""   
declare -a PREFERRED_ADD_LIST=()
CURRENT_INSTALL_MODE="recommended" 

FILE_PATH='./temp'     
ARGO_PORT=''         
TUIC_PORT=''         
HY2_PORT=''          
REALITY_PORT=''  


# --- UUID 处理函数 ---
handle_uuid_generation() {
  echo -e "${COLOR_MAGENTA}--- UUID 配置 ---${COLOR_RESET}"
  read_input "请输入您要使用的 UUID (留空则自动生成):" CUSTOM_UUID ""
  if [ -z "$CUSTOM_UUID" ]; then
    if command -v python3 &> /dev/null; then
      CUSTOM_UUID=$(python3 -c "import uuid; print(uuid.uuid4())")
      echo -e "${COLOR_GREEN}  ✓ 已通过 Python3 自动生成 UUID: ${COLOR_WHITE_BOLD}$CUSTOM_UUID${COLOR_RESET}"
    elif command -v python &> /dev/null; then
      CUSTOM_UUID=$(python -c "import uuid; print(uuid.uuid4())")
      echo -e "${COLOR_GREEN}  ✓ 已通过 Python 自动生成 UUID: ${COLOR_WHITE_BOLD}$CUSTOM_UUID${COLOR_RESET}"
    elif command -v uuidgen &> /dev/null; then
      CUSTOM_UUID=$(uuidgen)
      echo -e "${COLOR_GREEN}  ✓ 已通过 'uuidgen' 自动生成 UUID: ${COLOR_WHITE_BOLD}$CUSTOM_UUID${COLOR_RESET}"
    else
      echo -e "${COLOR_RED}  ✗ 错误: 'python' 和 'uuidgen' 命令均未找到。${COLOR_RESET}"
      read_input "请手动输入一个 UUID:" CUSTOM_UUID ""
      if [ -z "$CUSTOM_UUID" ]; then
        echo -e "${COLOR_RED}  ✗ 未提供 UUID，脚本无法继续。${COLOR_RESET}"
        exit 1
      fi
    fi
  else
    echo -e "${COLOR_GREEN}  ✓ 将使用您提供的 UUID: ${COLOR_WHITE_BOLD}$CUSTOM_UUID${COLOR_RESET}"
  fi
  echo
}

# --- 哪吒探针配置函数 (通用) ---
handle_nezha_config() {
    echo -e "${COLOR_MAGENTA}--- 哪吒探针配置 (可选) ---${COLOR_RESET}"
    read -p "$(echo -e ${COLOR_YELLOW}"[?] 是否配置哪吒探针? (y/N): "${COLOR_RESET})" configure_nezha
    if [[ "$(echo "$configure_nezha" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
      local default_nezha_method="1" 
      local nezha_prompt_text="[?] 自动解析[1] 或 手动输入[2]? [${default_nezha_method} (自动解析)]: "
      if [ "$CURRENT_INSTALL_MODE" == "custom" ]; then
        default_nezha_method="2" 
        nezha_prompt_text="[?] 自动解析[1] 或 手动输入[2]? [${default_nezha_method} (手动输入)]: "
      fi
      
      read -p "$(echo -e ${COLOR_YELLOW}"${nezha_prompt_text}"${COLOR_RESET})" nezha_input_choice
      nezha_input_choice=${nezha_input_choice:-$default_nezha_method} 

      if [[ "$nezha_input_choice" == "1" || "$(echo "$nezha_input_choice" | tr '[:upper:]' '[:lower:]')" == "p" ]]; then
        echo -e "${COLOR_CYAN}  请粘贴完整的哪吒 Agent 安装命令 (支持v0和v1):${COLOR_RESET}"
        read -r nezha_cmd_string
        
        if echo "$nezha_cmd_string" | grep -q "install_agent"; then
            local params=$(echo "$nezha_cmd_string" | awk -F'install_agent' '{print $2}' | xargs)
            NEZHA_SERVER=$(echo "$params" | awk '{print $1}')
            NEZHA_PORT=$(echo "$params" | awk '{print $2}')
            NEZHA_KEY=$(echo "$params" | awk '{print $3}')

            if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
              echo -e "${COLOR_GREEN}  ✓ 已从 v0 命令解析:${COLOR_RESET}"
              echo -e "${COLOR_GREEN}    NEZHA_SERVER: ${COLOR_WHITE_BOLD}${NEZHA_SERVER}${COLOR_RESET}"
              echo -e "${COLOR_GREEN}    NEZHA_PORT:   ${COLOR_WHITE_BOLD}${NEZHA_PORT}${COLOR_RESET}"
              echo -e "${COLOR_GREEN}    NEZHA_KEY:    ${COLOR_WHITE_BOLD}${NEZHA_KEY}${COLOR_RESET}"
            else
              echo -e "${COLOR_RED}  ✗ 未能从 v0 命令中解析出所有参数。${COLOR_RESET}"
              NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
            fi
        elif echo "$nezha_cmd_string" | grep -q "NZ_SERVER="; then
            NEZHA_SERVER_RAW=$(echo "$nezha_cmd_string" | grep -o 'NZ_SERVER=[^ ]*' | cut -d'=' -f2)
            NEZHA_KEY_RAW=$(echo "$nezha_cmd_string" | grep -o 'NZ_CLIENT_SECRET=[^ ]*' | cut -d'=' -f2)

            if [ -n "$NEZHA_SERVER_RAW" ] && [ -n "$NEZHA_KEY_RAW" ]; then
              NEZHA_SERVER="$NEZHA_SERVER_RAW"
              NEZHA_PORT=""
              NEZHA_KEY="$NEZHA_KEY_RAW"
              echo -e "${COLOR_GREEN}  ✓ 已从 v1 命令解析:${COLOR_RESET}"
              echo -e "${COLOR_GREEN}    NEZHA_SERVER: ${COLOR_WHITE_BOLD}${NEZHA_SERVER}${COLOR_RESET}"
              echo -e "${COLOR_GREEN}    NEZHA_PORT: (留空，端口已在SERVER中)${COLOR_RESET}"
              echo -e "${COLOR_GREEN}    NEZHA_KEY: ${COLOR_WHITE_BOLD}${NEZHA_KEY}${COLOR_RESET}"
            else
              echo -e "${COLOR_RED}  ✗ 未能从 v1 命令中解析出参数。${COLOR_RESET}"
              NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
            fi
        else
            echo -e "${COLOR_RED}  ✗ 未知的命令格式。${COLOR_RESET}"
            NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
        fi
      elif [[ "$nezha_input_choice" == "2" || "$(echo "$nezha_input_choice" | tr '[:upper:]' '[:lower:]')" == "m" ]]; then
        read_input "哪吒面板域名:" NEZHA_SERVER "" 
        read -p "$(echo -e ${COLOR_YELLOW}"[?] 域名是否已包含端口 (v1版特征)? (y/N): "${COLOR_RESET})" nezha_v1_style
        if [[ "$(echo "$nezha_v1_style" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
          NEZHA_PORT="" 
          echo -e "${COLOR_GREEN}  ✓ NEZHA_PORT 将留空 (v1 类型配置)。${COLOR_RESET}"
        else
          read_input "哪吒 Agent 端口:" NEZHA_PORT "" 
        fi
        read_input "哪吒密钥:" NEZHA_KEY
      else
        echo -e "${COLOR_RED}  ✗ 无效选择，跳过。${COLOR_RESET}"
        NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
      fi
    else
      NEZHA_SERVER=""; NEZHA_PORT=""; NEZHA_KEY=""
      echo -e "${COLOR_YELLOW}  跳过哪吒探针配置。${COLOR_RESET}"
    fi
    echo
}


# --- 检查并安装 jq ---
check_and_install_jq() {
  if command -v jq &> /dev/null; then
    echo -e "${COLOR_GREEN}  ✓ jq 已安装。${COLOR_RESET}"
    return 0
  fi

  echo -e "${COLOR_YELLOW}  jq 未安装，尝试自动安装...${COLOR_RESET}"
  if command -v apt-get &> /dev/null; then
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install jq -y >/dev/null 2>&1
  elif command -v yum &> /dev/null; then
    sudo yum install jq -y >/dev/null 2>&1
  else
    echo -e "${COLOR_RED}  ✗ 无法自动安装 jq。${COLOR_RESET}"
    return 1 
  fi

  if command -v jq &> /dev/null; then
    echo -e "${COLOR_GREEN}  ✓ jq 安装成功!${COLOR_RESET}"
    return 0
  else
    echo -e "${COLOR_RED}  ✗ jq 安装失败。${COLOR_RESET}"
    return 1 
  fi
}

# --- 防火墙端口放行函数 ---
open_firewall_ports() {
  echo -e "${COLOR_CYAN}  正在尝试打开防火墙端口...${COLOR_RESET}"
  local ports_to_open=()
  [[ "$CFPORT" =~ ^[0-9]+$ ]] && ports_to_open+=("$CFPORT")
  [[ "$ARGO_PORT" =~ ^[0-9]+$ ]] && ports_to_open+=("$ARGO_PORT")
  [[ "$TUIC_PORT" =~ ^[0-9]+$ ]] && ports_to_open+=("$TUIC_PORT")
  [[ "$HY2_PORT" =~ ^[0-9]+$ ]] && ports_to_open+=("$HY2_PORT")
  [[ "$REALITY_PORT" =~ ^[0-9]+$ ]] && ports_to_open+=("$REALITY_PORT")

  if [ ${#ports_to_open[@]} -eq 0 ]; then echo -e "${COLOR_YELLOW}  无有效端口，跳过。${COLOR_RESET}"; return; fi
  local unique_ports=($(echo "${ports_to_open[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')); echo -e "${COLOR_CYAN}  计划配置端口: ${unique_ports[*]}${COLOR_RESET}"; local firewall_configured=0
  if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    firewall_configured=1; echo -e "${COLOR_GREEN}  检测到 UFW，配置规则...${COLOR_RESET}"
    for port in "${unique_ports[@]}"; do
      sudo ufw allow "$port"/tcp >/dev/null 2>&1 && echo -e "${COLOR_GREEN}    ✓ 允许 TCP $port (UFW)。${COLOR_RESET}"
      sudo ufw allow "$port"/udp >/dev/null 2>&1 && echo -e "${COLOR_GREEN}    ✓ 允许 UDP $port (UFW)。${COLOR_RESET}"
    done
  elif command -v firewall-cmd &> /dev/null && sudo systemctl is-active --quiet firewalld; then
    firewall_configured=1; echo -e "${COLOR_GREEN}  检测到 Firewalld，配置规则...${COLOR_RESET}"
    for port in "${unique_ports[@]}"; do
      sudo firewall-cmd --permanent --add-port="$port"/tcp >/dev/null 2>&1 && echo -e "${COLOR_GREEN}    ✓ 添加 TCP $port (Firewalld)。${COLOR_RESET}"
      sudo firewall-cmd --permanent --add-port="$port"/udp >/dev/null 2>&1 && echo -e "${COLOR_GREEN}    ✓ 添加 UDP $port (Firewalld)。${COLOR_RESET}"
    done
    sudo firewall-cmd --reload >/dev/null 2>&1 && echo -e "${COLOR_GREEN}  ✓ Firewalld 重载成功。${COLOR_RESET}"
  elif command -v iptables &> /dev/null; then
    firewall_configured=1; echo -e "${COLOR_GREEN}  使用 iptables...${COLOR_RESET}"
    for port in "${unique_ports[@]}"; do
      ! sudo iptables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 && sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 && echo -e "${COLOR_GREEN}    ✓ 允许 TCP $port (iptables)。${COLOR_RESET}"
      ! sudo iptables -C INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 && sudo iptables -A INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 && echo -e "${COLOR_GREEN}    ✓ 允许 UDP $port (iptables)。${COLOR_RESET}"
    done
  fi
  if [ "$firewall_configured" -eq 0 ]; then echo -e "${COLOR_YELLOW}  未检测到防火墙，请手动开放端口: ${unique_ports[*]}${COLOR_RESET}"; fi
  echo
}


# --- 执行部署函数 ---
run_deployment() {
  print_header "开始部署流程" "${COLOR_CYAN}" 
  echo -e "${COLOR_CYAN}  当前配置预览 (模式: ${CURRENT_INSTALL_MODE}):${COLOR_RESET}"
  echo -e "    ${COLOR_WHITE_BOLD}UUID:${COLOR_RESET} $CUSTOM_UUID"
  echo -e "    ${COLOR_WHITE_BOLD}哪吒服务器:${COLOR_RESET} $NEZHA_SERVER"
  echo -e "    ${COLOR_WHITE_BOLD}哪吒端口:${COLOR_RESET} $NEZHA_PORT"
  echo -e "    ${COLOR_WHITE_BOLD}哪吒密钥:${COLOR_RESET} $NEZHA_KEY"
  echo -e "    ${COLOR_WHITE_BOLD}Argo域名:${COLOR_RESET} $ARGO_DOMAIN"
  echo -e "    ${COLOR_WHITE_BOLD}Argo授权:${COLOR_RESET} $ARGO_AUTH"
  echo -e "    ${COLOR_WHITE_BOLD}Argo端口:${COLOR_RESET} $ARGO_PORT"
  echo -e "    ${COLOR_WHITE_BOLD}节点名称 (NAME):${COLOR_RESET} $NAME"
  echo -e "    ${COLOR_WHITE_BOLD}主优选IP (CFIP):${COLOR_RESET} $CFIP (端口: $CFPORT)"
  echo -e "    ${COLOR_WHITE_BOLD}优选IP列表:${COLOR_RESET} ${PREFERRED_ADD_LIST[*]}"
  print_separator

  open_firewall_ports

  export UUID="$CUSTOM_UUID"; export NEZHA_SERVER="$NEZHA_SERVER"; export NEZHA_PORT="$NEZHA_PORT"; export NEZHA_KEY="$NEZHA_KEY"
  export ARGO_DOMAIN="$ARGO_DOMAIN"; export ARGO_AUTH="$ARGO_AUTH"; export ARGO_PORT="$ARGO_PORT"; export NAME="$NAME"
  export CFIP="$CFIP"; export CFPORT="$CFPORT"; export CHAT_ID="$CHAT_ID"; export BOT_TOKEN="$BOT_TOKEN"
  export UPLOAD_URL="$UPLOAD_URL"; export FILE_PATH="$FILE_PATH"; export TUIC_PORT="$TUIC_PORT"
  export HY2_PORT="$HY2_PORT"; export REALITY_PORT="$REALITY_PORT"

  SB_SCRIPT_PATH="/tmp/sb_core_script_$(date +%s%N).sh" 
  TMP_SB_OUTPUT_FILE=$(mktemp)
  if [ -z "$TMP_SB_OUTPUT_FILE" ]; then echo -e "${COLOR_RED}  ✗ 错误: 无法创建临时文件。${COLOR_RESET}"; exit 1; fi

  echo -e "${COLOR_CYAN}  > 正在下载核心脚本...${COLOR_RESET}"
  if curl -Lso "$SB_SCRIPT_PATH" https://main.ssss.nyc.mn/sb.sh; then
    chmod +x "$SB_SCRIPT_PATH"
    echo -e "${COLOR_GREEN}  ✓ 下载完成。${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  > 正在执行核心脚本 (请耐心等待)...${COLOR_RESET}" 

    bash "$SB_SCRIPT_PATH" > "$TMP_SB_OUTPUT_FILE" 2>&1 &
    SB_PID=$!

    TIMEOUT_SECONDS=60; elapsed_time=0
    local progress_chars="/-\\|"
    
    while ps -p $SB_PID > /dev/null && [ "$elapsed_time" -lt "$TIMEOUT_SECONDS" ]; do
      printf "\r${COLOR_YELLOW}  [执行中 ${progress_chars:$((elapsed_time % 4)):1}] (已用时: ${elapsed_time}s)${COLOR_RESET}"
      sleep 1
      ((elapsed_time++))
    done
    printf "\r${COLOR_GREEN}  [核心脚本执行完毕或超时]                                  ${COLOR_RESET}\n"
    
    if ps -p $SB_PID > /dev/null; then 
      echo -e "${COLOR_RED}  ✗ 核心脚本执行超时，尝试终止...${COLOR_RESET}"; kill -9 $SB_PID
    else 
      wait $SB_PID
    fi
    
    rm "$SB_SCRIPT_PATH"
  else
    echo -e "${COLOR_RED}  ✗ 错误: 下载核心脚本失败。${COLOR_RESET}"; echo "Error: sb.sh download failed." > "$TMP_SB_OUTPUT_FILE"
  fi
  
  RAW_SB_OUTPUT=$(cat "$TMP_SB_OUTPUT_FILE"); rm "$TMP_SB_OUTPUT_FILE"; echo

  print_header "部署结果分析与链接生成" "${COLOR_CYAN}" 
  if [ -z "$RAW_SB_OUTPUT" ]; then echo -e "${COLOR_RED}  ✗ 错误: 未能捕获到核心脚本输出。${COLOR_RESET}"; else
    check_and_install_jq; echo
    echo -e "${COLOR_MAGENTA}--- 核心脚本执行结果摘要 ---${COLOR_RESET}"
    ARGO_DOMAIN_OUTPUT=$(echo "$RAW_SB_OUTPUT" | grep "ArgoDomain:"); if [ -n "$ARGO_DOMAIN_OUTPUT" ]; then ARGO_ACTUAL_DOMAIN=$(echo "$ARGO_DOMAIN_OUTPUT" | awk -F': ' '{print $2}'); echo -e "${COLOR_CYAN}  Argo 域名:${COLOR_RESET} ${COLOR_WHITE_BOLD}${ARGO_ACTUAL_DOMAIN}${COLOR_RESET}"; else echo -e "${COLOR_YELLOW}  未检测到 Argo 域名。${COLOR_RESET}"; fi
    ORIGINAL_VMESS_LINK=$(echo "$RAW_SB_OUTPUT" | grep "vmess://" | head -n 1); declare -a GENERATED_VMESS_LINKS_ARRAY=()
    if [ -z "$ORIGINAL_VMESS_LINK" ]; then echo -e "${COLOR_YELLOW}  未检测到 VMess 链接。${COLOR_RESET}"; else
      echo -e "${COLOR_GREEN}  正在处理 VMess 配置链接...${COLOR_RESET}"
      if command -v jq &> /dev/null && command -v base64 &> /dev/null; then
        BASE64_DECODE_CMD="base64 -d"; BASE64_ENCODE_CMD="base64 -w0"; [[ "$(uname)" == "Darwin" ]] && BASE64_DECODE_CMD="base64 -D" && BASE64_ENCODE_CMD="base64"
        BASE64_PART=$(echo "$ORIGINAL_VMESS_LINK" | sed 's/vmess:\/\///'); JSON_CONFIG=$($BASE64_DECODE_CMD <<< "$BASE64_PART" 2>/dev/null) 
        if [ -n "$JSON_CONFIG" ]; then
          ORIGINAL_PS=$(echo "$JSON_CONFIG" | jq -r .ps 2>/dev/null); [[ -z "$ORIGINAL_PS" || "$ORIGINAL_PS" == "null" ]] && ORIGINAL_PS="节点"
          if [ ${#PREFERRED_ADD_LIST[@]} -eq 0 ]; then PREFERRED_ADD_LIST=("cloudflare.182682.xyz" "joeyblog.net"); fi
          UNIQUE_PREFERRED_ADD_LIST=($(echo "${PREFERRED_ADD_LIST[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')); echo -e "${COLOR_GREEN}  生成的优选地址 VMess 链接:${COLOR_RESET}"
          for target_add in "${UNIQUE_PREFERRED_ADD_LIST[@]}"; do
            NEW_PS="${ORIGINAL_PS}-优选-$(echo "$target_add" | sed 's/[^a-zA-Z0-9_.-]/_/g')"
            MODIFIED_JSON=$(echo "$JSON_CONFIG" | jq --arg new_add "$target_add" --arg new_ps "$NEW_PS" '.add = $new_add | .ps = $new_ps')
            if [ -n "$MODIFIED_JSON" ]; then MODIFIED_BASE64=$(echo -n "$MODIFIED_JSON" | $BASE64_ENCODE_CMD); GENERATED_VMESS_LINK="vmess://${MODIFIED_BASE64}"; echo -e "    ${COLOR_WHITE_BOLD}${GENERATED_VMESS_LINK}${COLOR_RESET}"; GENERATED_VMESS_LINKS_ARRAY+=("$GENERATED_VMESS_LINK"); fi
          done
        fi
      fi
    fi; echo
    
    echo -e "${COLOR_MAGENTA}--- 其他协议链接 ---${COLOR_RESET}"
    echo "$RAW_SB_OUTPUT" | grep "tuic://" | while IFS= read -r line; do echo -e "${COLOR_GREEN}  TUIC:${COLOR_RESET} ${COLOR_WHITE_BOLD}$line${COLOR_RESET}"; done
    echo "$RAW_SB_OUTPUT" | grep "hysteria2://" | while IFS= read -r line; do echo -e "${COLOR_GREEN}  Hysteria2:${COLOR_RESET} ${COLOR_WHITE_BOLD}$line${COLOR_RESET}"; done
    echo "$RAW_SB_OUTPUT" | grep -E "vless://[^\"]*reality" | while IFS= read -r line; do echo -e "${COLOR_GREEN}  VLESS (Reality):${COLOR_RESET} ${COLOR_WHITE_BOLD}$line${COLOR_RESET}"; done
    echo

    if [ ${#GENERATED_VMESS_LINKS_ARRAY[@]} -gt 0 ] && command -v jq &> /dev/null; then
      echo -e "${COLOR_MAGENTA}--- Clash 订阅链接 (通过 api.wcc.best) ---${COLOR_RESET}"
      RAW_VMESS_STRING=$(printf "%s|" "${GENERATED_VMESS_LINKS_ARRAY[@]}"); RAW_VMESS_STRING=${RAW_VMESS_STRING%|}
      ENCODED_VMESS_STRING=$(echo -n "$RAW_VMESS_STRING" | jq -Rr @uri)
      CONFIG_URL_ENCODED=$(echo -n "https://raw.githubusercontent.com/byJoey/test/refs/heads/main/tist.ini" | jq -Rr @uri)
      FINAL_CLASH_API_URL="https://api.wcc.best/sub?target=clash&url=${ENCODED_VMESS_STRING}&insert=false&config=${CONFIG_URL_ENCODED}&emoji=true&list=false&tfo=false&scv=true&fdn=false&expand=true&sort=false&new_name=true"
      echo -e "${COLOR_GREEN}  ✓ Clash 订阅 URL:${COLOR_RESET}"; echo -e "    ${COLOR_WHITE_BOLD}${FINAL_CLASH_API_URL}${COLOR_RESET}"
    fi; echo
    
    echo "$RAW_SB_OUTPUT" | grep "\.\/\.tmp\/sub\.txt saved successfully" | sed "s/^/${COLOR_GREEN}✓ 订阅文件: /;s/$/${COLOR_RESET}/"
    echo "$RAW_SB_OUTPUT" | grep "安装完成" | head -n 1 | sed "s/^/${COLOR_GREEN}✓ 状态: /;s/$/${COLOR_RESET}/"
    echo "$RAW_SB_OUTPUT" | grep "一键卸载命令：" | sed "s/一键卸载命令：/${COLOR_RED}一键卸载命令:${COLOR_RESET} ${COLOR_WHITE_BOLD}/;s/$/${COLOR_RESET}/"
  fi 
  
  sudo iptables -F
  # 在所有部署任务完成后，启动保活脚本
  start_keepalive_heartbeat
}

# --- 主菜单 ---
print_header "IBM-sb-ws 部署模式选择" "${COLOR_CYAN}" 
echo -e "${COLOR_WHITE_BOLD}  1) 推荐安装${COLOR_RESET} (可配置UUID、优选IP、哪吒探针)"
echo -e "${COLOR_WHITE_BOLD}  2) 自定义安装${COLOR_RESET} (手动配置所有参数)" 
echo -e "${COLOR_WHITE_BOLD}  Q) 退出脚本${COLOR_RESET}"
print_separator
read -p "$(echo -e ${COLOR_YELLOW}"请输入选项 [1]: "${COLOR_RESET})" main_choice
main_choice=${main_choice:-1} 

case "$main_choice" in
  1) 
    CURRENT_INSTALL_MODE="recommended"
    echo
    print_header "推荐安装模式" "${COLOR_MAGENTA}" 
    echo -e "${COLOR_CYAN}此模式将使用核心配置。节点名称默认为 'ibm'。${COLOR_RESET}"
    echo
    handle_uuid_generation 
    handle_nezha_config
    
    DEFAULT_PREFERRED_IPS_REC="cloudflare.182682.xyz,joeyblog.net"
    read_input "请输入优选IP或域名列表 (逗号隔开):" USER_PREFERRED_IPS_INPUT_REC "${DEFAULT_PREFERRED_IPS_REC}"
    
    PREFERRED_ADD_LIST=() 
    IFS=',' read -r -a temp_array_rec <<< "$USER_PREFERRED_IPS_INPUT_REC"
    for item in "${temp_array_rec[@]}"; do
      trimmed_item=$(echo "$item" | xargs) 
      if [ -n "$trimmed_item" ]; then PREFERRED_ADD_LIST+=("$trimmed_item"); fi
    done

    ARGO_DOMAIN=""; ARGO_AUTH=""
    NAME="ibm" 
    if [ ${#PREFERRED_ADD_LIST[@]} -gt 0 ]; then CFIP="${PREFERRED_ADD_LIST[0]}"; else CFIP="cloudflare.182682.xyz"; fi
    CFPORT="443" 
    CHAT_ID=""; BOT_TOKEN=""; UPLOAD_URL=""
    FILE_PATH='./temp'; ARGO_PORT=$(shuf -i 2000-65535 -n 1); TUIC_PORT=''; HY2_PORT=''; REALITY_PORT='8008' 
    run_deployment
    ;;
  2) 
    CURRENT_INSTALL_MODE="custom"
    echo
    print_header "自定义安装模式" "${COLOR_MAGENTA}"
    echo -e "${COLOR_CYAN}此模式允许您手动配置各项参数。${COLOR_RESET}"
    echo
    handle_uuid_generation 
    handle_nezha_config

    echo -e "${COLOR_MAGENTA}--- Argo 隧道配置 (可选) ---${COLOR_RESET}"
    read -p "$(echo -e ${COLOR_YELLOW}"[?] 是否配置 Argo 隧道? (y/N): "${COLOR_RESET})" configure_section
    if [[ "$(echo "$configure_section" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
      read_input "Argo 域名 (留空则启用临时隧道):" ARGO_DOMAIN ""
      if [ -n "$ARGO_DOMAIN" ]; then read_input "Argo Token 或 JSON:" ARGO_AUTH; else ARGO_AUTH=""; fi
    else
      ARGO_DOMAIN=""; ARGO_AUTH=""
    fi
    echo
    
    echo -e "${COLOR_MAGENTA}--- 核心参数配置 ---${COLOR_RESET}" 
    read_input "节点名称:" NAME "${NAME}" 
      
    DEFAULT_PREFERRED_IPS_CUST_DISPLAY=$(echo "$CFIP,joeyblog.net,cloudflare.182682.xyz" | tr ',' '\n' | sort -u | paste -sd, -)
    read_input "请输入优选IP或域名列表 (逗号隔开):" USER_PREFERRED_IPS_INPUT_CUST "${DEFAULT_PREFERRED_IPS_CUST_DISPLAY}"

    PREFERRED_ADD_LIST=() 
    IFS=',' read -r -a temp_array_cust <<< "$USER_PREFERRED_IPS_INPUT_CUST"
    for item in "${temp_array_cust[@]}"; do
      trimmed_item_cust=$(echo "$item" | xargs) 
      if [ -n "$trimmed_item_cust" ]; then PREFERRED_ADD_LIST+=("$trimmed_item_cust"); fi
    done
      
    if [ ${#PREFERRED_ADD_LIST[@]} -gt 0 ]; then
        CFIP="${PREFERRED_ADD_LIST[0]}" 
        read_input "为主优选IP (${CFIP}) 设置端口:" CFPORT "443"
    fi
    
    read_input "Argo 端口 (固定隧道用):" ARGO_PORT ""
    read_input "Sub 文件保存路径:" FILE_PATH "${FILE_PATH}"

    echo
    echo -e "${COLOR_MAGENTA}--- 额外协议端口配置 (可选) ---${COLOR_RESET}"
    read_input "TUIC 端口:" TUIC_PORT ""
    read_input "Hysteria2 端口:" HY2_PORT ""
    read_input "REALITY 端口:" REALITY_PORT ""

    echo
    echo -e "${COLOR_MAGENTA}--- Telegram推送配置 (可选) ---${COLOR_RESET}"
    read_input "Telegram Chat ID:" CHAT_ID ""
    if [ -n "$CHAT_ID" ]; then read_input "Telegram Bot Token:" BOT_TOKEN ""; fi
    
    echo
    echo -e "${COLOR_MAGENTA}--- 节点信息上传 (可选) ---${COLOR_RESET}"
    read_input "节点信息上传 URL:" UPLOAD_URL ""
    
    run_deployment
    ;;
  [Qq]*) 
    echo -e "${COLOR_GREEN}已退出向导。感谢使用!${COLOR_RESET}"
    exit 0
    ;;
  *) 
    echo -e "${COLOR_RED}无效选项，将执行推荐安装。${COLOR_RESET}"
    # Fallback to recommended install
    CURRENT_INSTALL_MODE="recommended"
    echo
    print_header "推荐安装模式 (默认执行)" "${COLOR_MAGENTA}" 
    echo -e "${COLOR_CYAN}此模式将使用核心配置。节点名称默认为 'ibm'。${COLOR_RESET}"
    echo
    handle_uuid_generation 
    handle_nezha_config
    
    DEFAULT_PREFERRED_IPS_REC="cloudflare.182682.xyz,joeyblog.net"
    read_input "请输入优选IP或域名列表 (逗号隔开):" USER_PREFERRED_IPS_INPUT_REC "${DEFAULT_PREFERRED_IPS_REC}"
    
    PREFERRED_ADD_LIST=() 
    IFS=',' read -r -a temp_array_rec <<< "$USER_PREFERRED_IPS_INPUT_REC"
    for item in "${temp_array_rec[@]}"; do
      trimmed_item=$(echo "$item" | xargs) 
      if [ -n "$trimmed_item" ]; then PREFERRED_ADD_LIST+=("$trimmed_item"); fi
    done

    ARGO_DOMAIN=""; ARGO_AUTH=""
    NAME="ibm" 
    if [ ${#PREFERRED_ADD_LIST[@]} -gt 0 ]; then CFIP="${PREFERRED_ADD_LIST[0]}"; else CFIP="cloudflare.182682.xyz"; fi
    CFPORT="443" 
    CHAT_ID=""; BOT_TOKEN=""; UPLOAD_URL=""
    FILE_PATH='./temp'; ARGO_PORT=$(shuf -i 2000-65535 -n 1); TUIC_PORT=''; HY2_PORT=''; REALITY_PORT='8008' 
    run_deployment
    ;;
esac
exit 0
