#!/bin/bash
set -e

#安装unzip，用于后面的解压
rpm -Uvh ./*.rpm --nodeps --force;

echo "----- 正在安装系统依赖开发包 -------"

unzip -o packages.zip && rpm -Uvh ./packages/*.rpm --nodeps --force;

echo "---- 系统依赖开发包安装完毕 ------"

echo "---- 安装luaJIT------F--"

unzip -o LuaJIT.zip && cd LuaJIT/;
make && make install;
ln -sf luajit-2.1.0-beta3 /usr/local/bin/luajit;
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1;
unzip -o ../lua-cjson.zip -d .. && cd ../lua-cjson/;
make && make install;
unzip -o ../lua-resty-http.zip -d .. && cd ../lua-resty-http/;
make && make install;

echo "---- luaJIT安装成功--------"

echo "-----开始编译安装nginx------"
cd .. && unzip -o nginx.zip && unzip -o nginx-upload-module.zip && unzip -o nginx-upload-progress-module.zip  && unzip -o lua-nginx-module.zip && unzip -o ngx_devel_kit.zip && cd nginx/;
chmod +x configure;
./configure --add-module=../nginx-upload-module --add-module=../nginx-upload-progress-module --add-module=../lua-nginx-module --add-module=../ngx_devel_kit --with-ld-opt="-Wl,-rpath,/usr/local/lib";
make && make install;
echo "---- nginx成功编译成功，安装位置在/usr/local/nginx";

echo "---- 开始覆盖nginx的配置文件-------"
cd ..;
if [ -d "/usr/local/nginx/lua" ];then
   rm -rf /usr/local/nginx/lua_bak;
   mv -f /usr/local/nginx/lua /usr/local/nginx/lua_bak;
fi
mv -f  lua/ /usr/local/nginx/;
mv -f nginx.conf /usr/local/nginx/conf;
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
if [ ! -d "/home/uploadStore/" ];then
mkdir /home/uploadStore;
fi
mv 1.jpg /home/uploadStore;

echo "-----开始安装转码软件ffmpeg------"

rm -rf /opt/ffmpeg/;
unzip -o ffmpeg.zip && cp -rf  ffmpeg/ /opt/;
chmod +x /opt/ffmpeg/ffmpeg;
rm -rf /usr/bin/ffmpeg;
ln -s /opt/ffmpeg/ffmpeg /usr/bin/ffmpeg;

echo "-----转码软件ffmpeg安装成功------"

echo "----正在启动文件服务器"
nginx;
echo "----文件服务器启动成功。默认开放端口为8090。测试文件路径为http://ip:8090/1.jpg"

echo "----正在开放8090端口"
firewall-cmd --zone=public --add-port=8090/tcp --permanent;
systemctl restart firewalld.service;
echo "---- 8090端口开放成功-------"




