# auto-ssl-renew
一个简易的ssl自动更新小脚本，部署只需5分钟。  
acme可实现自动修改dns并申请泛域名证书，因此写了这个小脚本，以方便在申请之后分发到每个客户端机器。  

只有2个文件
### renew.sh  
用于部署在服务器（或其他任何可以公网访问的机器，比如内网穿透的树莓派或有公网IP的nas），acme申请泛域名证书的示例脚本，只需部署一个实例即可

### sslreload_web.sh  
所有需要证书的客户端机器执行该脚本自动拉取并更新证书



# 使用方法  

## 1. 安装acme脚本
```
因网络问题 中国区安装参考这个 https://github.com/acmesh-official/acme.sh/wiki/Install-in-China  
# 建议安装的时候就设置邮箱，后续如果申请lets证书就不用重复设置
git clone https://gitee.com/neilpang/acme.sh.git
cd acme.sh
./acme.sh --install -m my@example.com
```

## 2.下载auto-ssl-renew并修改里面的默认配置为你的
```
git clone https://github.com/del-xiong/auto-ssl-renew.git && cd auto-ssl-renew  

```
中国区
```
git clone https://gitee.com/splot/auto-ssl-renew.git && cd auto-ssl-renew  

```

### renew 文件配置
renew_ 文件名和路径修改，给文件名添加复杂hash避免泄露路径(这是为了避免部分用户误将该文件部署到web目录被别人下载)  
运行下面的命令进行**初始化**
```

# 初始化 一键运行 直接复制下面的命令回车
rndhash=$(head -64 /dev/urandom |sha256sum|head -c 32) && \
find sslreload_web.sh -type f -print0 | xargs -0 sed -i "s/RNDHASH=\"\"/RNDHASH=\"${rndhash}\"/g" && \
mv sslreload_web.sh "sslreload_${rndhash}.sh" && \
mv renew.sh "renew_${rndhash}.sh" && \
ls && echo "初始化完毕" && \
echo "请将 renew_${rndhash}.sh 移动到你的系统目录" && \
echo "并将 sslreload_${rndhash}.sh 移动到web目录"
```
上面命令的作用是将脚本重命名添加随机值，避免文件名太简单被别人爆破

renew文件不需要web访问，所以可以放到系统目录 例如/root/renew_*.sh

修改renew_*.sh，将里面的示例申请代码移除，**替换为你自己的**  

修改**OUTPUT变量值**，改为你的web目录的路径，例如 /www/html/sslrenew/ (末尾带斜杠)  

注意不同解析服务商可能需要设置不同的环境变量，acme支持上百家dns服务商，具体参考 https://github.com/acmesh-official/acme.sh/wiki/dnsapi

renew文件末尾，申请完毕所有证书后建议将证书文件所有者改为你的web用户组，以避免权限问题导致证书无法拉取  
例如你的web用户组是www 则执行
```
chown www:www -R $OUTPUT
```
还有个办法是直接使用web组运行acme，不过这样的话安装acme也需要安装在web用户目录下。

### sslreload_web 文件配置 
sslreload文件需要修改server_path变量为你的web目录路径例如 https://abc.com/  
然后直接将文件放到你的web目录确保可访问即可，例如 /www/html/sslrenew/sslreload_web.sh


## 3. 更新证书
部署计划任务，执行证书自动更新任务，建议每日一次  
例如 通过crond添加计划任务  
假设：
初始化时你生成的renew路径是 renew_23d02c1ae87f8f898730e41889bdab5f.sh  
sslreload路径是 sslreload_23d02c1ae87f8f898730e41889bdab5f.sh
```
0 0 * * * bash /root/renew_23d02c1ae87f8f898730e41889bdab5f.sh
```
默认在证书过期前一个月续期，未过期的会跳过，如果你想强制续期，可以删除~/.acme.sh/目录里对应的域名目录

## 4. 客户端如何更新证书
完成第3步检查证书申请正常后，你的web目录应该就有你的域名证书了，所有需要拉取证书的客户端都可以一行命令直接更新证书，例如  
(假如你的证书更新域名是 https://helloworld.com 想更新 openai.com 的证书 )
```
curl https://abc.com/sslreload_23d02c1ae87f8f898730e41889bdab5f.sh -k|bash -s openai.com /www/ssl  'nginx force-reload';

```
sslreload_web -s 参数解释  
openai.com: 你要拉去证书的域名  
/www/ssl/: 证书拉取成功后要放置到目录 /www/ssl  
'nginx force-reload': 证书更新成功后你想执行的命令例如 强制reload下nginx 

如果你看到如下消息，那说明就成功了
```
下载域名证书成功
key文件路径 /www/ssl/all.openai.com.key
cert文件路径 /www/ssl/all.openai.com.cert
开始执行命令 '/etc/init.d/nginx force-reload'
Reload service nginx...  done
```

**Enjoy!**

## 5. 附录，如果想隐藏证书路径的建议
在上面的证书申请中，证书路径中包含了一个RNDHASH的随机值，从而避免了被外人爆破的风险，但仍可能存在内部泄露的风险，例如考虑一种这样的情况:  
- 你是某个小团队中的一员，使用脚本自动更新某个项目证书，其他团队成员也可能看到你的证书更新命令，那么他如果恰好知道你的其他域名，就存在遍历你的证书路径来下载证书的风险。

为了解决这个问题，你可以对部分证书设置不一样的命名方式，例如查看renew文件中的suffix="cf77713322c2463bf"下面的命令，我在申请这个域名的时候额外赋予了一个随机hash值，这样其他用户在不知道这个hash的情况下很难通过遍历的方式下载到你的证书。（因为renew文件对外部不可见）  

同样的，拉取命令也需要指定这个hash参数（第4个参数）  

上面的命令就需要变为  
```
curl https://abc.com/sslreload_23d02c1ae87f8f898730e41889bdab5f.sh -k|bash -s openai.com /www/ssl  'nginx force-reload' cf77713322c2463bf;
```