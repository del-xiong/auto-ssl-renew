#!/bin/bash


# 默认文件随机值 避免爆破
RNDHASH=$(basename -- "$0")
RNDHASH=${RNDHASH#*_}
RNDHASH=${RNDHASH%.*}
# 修改dns后等待多少秒
DNSSLEEP="120"
# 证书生成后的存放位置
OUTPUT="/www/html/"


# 默认使用zerossl 参考 https://github.com/acmesh-official/acme.sh/wiki/Change-default-CA-to-ZeroSSL
~/.acme.sh/acme.sh  --set-default-ca --server zerossl
# 申请lets证书 ~/.acme.sh/acme.sh  --set-default-ca --server letsencrypt

# 阿里解析申请示例 登录阿里云创建子密钥并授权
export Ali_Key=""
export Ali_Secret=""
domains=("example.com" "example.net")
for item in ${domains[*]}
do
  echo "开始检查域名【$item】"
  ~/.acme.sh/acme.sh --issue --dns dns_ali -d $item -d "*.${item}" --dnssleep $DNSSLEEP --fullchain-file "${OUTPUT}all${RNDHASH}.${item}.cert" --key-file "${OUTPUT}all${RNDHASH}.${item}.key"
done


# dnspod申请示例 登录 https://console.dnspod.cn/account/token/token 创建token
export DP_Id=""
export DP_Key=""
domains=("example.com" "example.net")
for item in ${domains[*]}
do
  echo "开始检查域名【$item】"
  ~/.acme.sh/acme.sh --issue --dns dns_dp -d $item -d "*.${item}" --dnssleep $DNSSLEEP --fullchain-file "${OUTPUT}all${RNDHASH}.${item}.cert" --key-file "${OUTPUT}all${RNDHASH}.${item}.key"
done

# he.net申请示例 勾选域名记录的Enable entry for dynamic dns，然后为该记录创建一条动态更新key即可
export HE_Username=""
export HE_Password=""
domains=("example.com" "example.net")
suffix="cf77713322c2463bf"
for item in ${domains[*]}
do
  echo "开始检查域名【$item】"
  ~/.acme.sh/acme.sh --issue --dns dns_he -d $item -d "*.${item}" --dnssleep $DNSSLEEP --fullchain-file "${OUTPUT}all${RNDHASH}.${item}.${suffix}.cert" --key-file "${OUTPUT}all${RNDHASH}.${item}.${suffix}.key"
done

# cloudflare申请示例 需要去官网登录获取token和账户ID email
domains=("example.com" "example.net")
export CF_Token=""
export CF_Email=""
export CF_Account_ID=""
suffix=""
for item in ${domains[*]}
do
  echo "开始检查域名【$item】"
  ~/.acme.sh/acme.sh --issue  --dns dns_cf -d $item -d "*.${item}" --dnssleep $DNSSLEEP --fullchain-file "${OUTPUT}all${RNDHASH}.${item}.${suffix}.cert" --key-file "${OUTPUT}all${RNDHASH}.${item}.${suffix}.key"
done

# 如果要给web服务读取，建议授权一下web用户组
# chown www:www -R $OUTPUT

