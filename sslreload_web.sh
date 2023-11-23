#!/bin/bash

RNDHASH=""


if [ ! -n "$3" ]; then
	echo "参数不正确 格式为 sslreload.sh [根域名] [证书保存路径] [完成后执行命令]"
	echo "例如 sh sslreload.sh katamao.com /www/server/panel/ssl/ \"bt reload\""
	exit
fi

server_path=""
if [[ -z "$server_path" ]]; then
    echo "sslreload的server_path未设置，请设置为你的证书拉取路径再重试"
    exit
fi
begin_str="\-\-BEGIN"
echo "开始下载域名证书 【${1}】"
# 如果定义了suffix参数
if [ -n "$4" ]; then
  curl -o acme-renew.key -k "${server_path}all${RNDHASH}.$1.$4.key"
  curl -o acme-renew.cert -k "${server_path}all${RNDHASH}.$1.$4.cert"
else
  curl -o acme-renew.key -k "${server_path}all${RNDHASH}.$1.key"
  curl -o acme-renew.cert -k "${server_path}all${RNDHASH}.$1.cert"
fi

if cat acme-renew.key | grep $begin_str > /dev/null && cat acme-renew.cert | grep $begin_str > /dev/null; then
  if mv acme-renew.key "${2}/all.${1}.key" && mv acme-renew.cert "${2}/all${RNDHASH}.${1}.cert" ; then
	  echo "下载域名证书成功"
	  echo "key文件路径 ${2}/all.${1}.key"
	  echo "cert文件路径 ${2}/all.${1}.cert"
	  echo "开始执行命令 '${3}'"
	  $3
  else
  	  echo "复制证书时失败 请确认目录正确"
  fi
else
	echo "下载证书失败，请确认网络和服务器(${server_path})正常以及域名(${1})正确无误"
fi
rm -rf acme-renew.key
rm -rf acme-renew.cert