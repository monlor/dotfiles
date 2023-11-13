#!/bin/bash 

easyfrp() {
  if [ -z "${1}" ]; then
    echo "参数错误！格式：easyfrp 本地IP:端口 远程端口"
    return 1
  fi
  local server_ip=$(echo ${FRP_SERVER} | cut -d ':' -f 1)
  local server_port=$(echo ${FRP_SERVER} | cut -d ':' -f 2)
  local local_ip=$(echo ${1} | cut -d ':' -f 1)
  local local_port=$(echo ${1} | cut -d ':' -f 2)
  local start_port=$(echo ${FRP_ALLOW_PORTS} | cut -d '-' -f1)
  local end_port=$(echo ${FRP_ALLOW_PORTS} | cut -d '-' -f2)
  local remote_port=${2:-$(( RANDOM % (end_port-start_port+1) + start_port ))}
  echo "将本地服务：${local_ip:-127.0.0.1}:${local_port} 映射到远程：${server_ip}:${remote_port}"
  frpc tcp -n ${remote_port} -s ${server_ip}:${server_port} -t ${FRP_TOKEN} -i ${local_ip:-127.0.0.1} -l ${local_port} -r ${remote_port}
}
