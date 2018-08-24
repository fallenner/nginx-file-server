#!/bin/bash

echo "----- 安装编译nginx必备的开发包 -------" 
set -e
#yum install -y pcre pcre-devel  zlib zlib-devel  openssl openssl-devel gcc vim;

rpm -Uvh ./packages/*.rpm --nodeps --force;

echo "---- 安装开发包成功 ------"

echo "---- 安装luaJIT--------"
cd LuaJIT/;
make && make install;
ln -sf luajit-2.1.0-beta3 /usr/local/bin/luajit;
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1;
cd ../lua-cjson/;
make && make install;
cd ../lua-resty-http/;
make && make install;
echo "---- luaJIT安装成功--------"

echo "-----开始编译安装nginx------"
cd ../nginx/;
chmod +x configure;
./configure --add-module=../nginx-upload-module --add-module=../nginx-upload-progress-module --add-module=../lua-nginx-module --add-module=../ngx_devel_kit --with-ld-opt="-Wl,-rpath,/usr/local/lib";
make && make install;
echo "---- nginx成功编译成功，安装位置在/usr/local/nginx";

echo "---- 开始覆盖nginx的配置文件-------"
cd ..;
rm -rf /usr/local/nginx/lua/;  
mv  lua/ /usr/local/nginx/;
echo "---- 覆盖nginx的配置文件成功-------"

#创建全局可用的nginx命令
rm -rf /usr/bin/nginx;
ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx;

#新建nginx文件上传临时存放目录和断点续传目录
rm -rf /usr/tmp/ngx_store;
rm -rf /usr/tmp/upload_temp;
mkdir /usr/tmp/ngx_store;
mkdir /usr/tmp/upload_temp;

#新建文件服务器仓库
rm -rf /opt/uploadStore;
mkdir /opt/uploadStore;
mv 1.jpg /opt/uploadStore;

echo "-----安装转码软件ffmpeg------"
rm -rf /opt/ffmpeg/;
mv  ffmpeg/ /opt/;
chmod +x /opt/ffmpeg/ffmpeg;
rm -rf /usr/bin/ffmpeg;
ln -s /opt/ffmpeg/ffmpeg /usr/bin/ffmpeg;

#开放8090端口
firewall-cmd --zone=public --add-port=8090/tcp --permanent;
systemctl restart firewalld.service;

#启动nginx
nginx;
#删除解压文件
rm -rf  lua-cjson LuaJIT nginx lua-nginx-module lua-resty-http nginx-upload-module nginx-upload-progress-module ngx_devel_kit 1.jpg;
echo "---- nginx启动成功，默认开放端口为8090。测试文件路径为http://ip:8090/1.jpg-------"




