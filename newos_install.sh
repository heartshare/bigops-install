#!/bin/sh

stty erase '^H'

/bin/sh /opt/bigops/bin/check_env.sh

cp -f /opt/bigops/install/yum.repos.d/* /etc/yum.repos.d/

which "make" > /dev/null
if [ $? != 0 ];then
    yum -y install make
fi

which "gcc" > /dev/null
if [ $? != 0 ];then
    yum -y install gcc
fi

which "g++" > /dev/null
if [ $? != 0 ];then
    yum -y install gcc-c++
fi

which "medusa" > /dev/null
if [ $? != 0 ];then
    yum -y install libssh2 openssl openssl-libs openssl-devel
    cd /opt/bigops/install/soft/
    tar zxvf medusa-2.2.tar.gz
    cd medusa-2.2
     ./configure --prefix=/usr
    make && make install
fi

if [ -z "$(nmap -V|egrep 7.70)" ];then
    cd /opt/bigops/install/soft/
    tar zxvf nmap-7.70.tgz
    cd nmap-7.70
    ./configure --prefix=/usr
    make && make install
fi

which "ansible" > /dev/null
if [ $? != 0 ];then
    yum -y install ansible
fi
cp -f /opt/bigops/install/ansible.cfg /root/.ansible.cfg
sed -i 's/^[ ]*StrictHostKeyChecking.*/StrictHostKeyChecking no/g' /etc/ssh/ssh_config

if [ -f /usr/bin/jqbak ];then
    cp -f /opt/bigops/install/soft/jq-linux64 /usr/bin/jq
else
    cp  /usr/bin/jq /usr/bin/jqbak
    cp -f /opt/bigops/install/soft/jq-linux64 /usr/bin/jq
fi
chmod 777 /usr/bin/jq

which "nginx" > /dev/null
if [ $? != 0 ];then
    yum -y install nginx
fi

if [ ! -d /opt/ngxlog/ ];then
    mkdir /opt/ngxlog
fi

cp -f /opt/bigops/config/bigops.properties.example /opt/bigops/config/bigops.properties

echo -e "please input sso url, for example: sso.bigops.com"
echo -e ">\c"
read ssourl
ssourl=`echo "$ssourl"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`

echo -e "please input homeurl, for example: work.bigops.com"
echo -e ">\c"
read homeurl
homeurl=`echo "$homeurl"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`

cp -f /opt/bigops/install/lnmp_conf/nginx.conf /etc/nginx/nginx.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/default.conf /etc/nginx/conf.d/default.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/sso.conf /etc/nginx/conf.d/sso.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/work.conf /etc/nginx/conf.d/work.conf
cp -f /opt/bigops/install/lnmp_conf/conf.d/zabbix.conf /etc/nginx/conf.d/zabbix.conf

sed -i "s#^[ \t]*server_name.*#    server_name ${ssourl};#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*server_name.*#    server_name ${homeurl};#g" /etc/nginx/conf.d/work.conf

sed -i "s#^[ \t]*access_log.*#    access_log  /opt/ngxlog/${ssourl}.access.log main;#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*access_log.*#    access_log  /opt/ngxlog/${homeurl}.access.log main;#g" /etc/nginx/conf.d/work.conf

sed -i "s#^[ \t]*error_log.*#    error_log  /opt/ngxlog/${ssourl}.error.log;#g" /etc/nginx/conf.d/sso.conf
sed -i "s#^[ \t]*error_log.*#    error_log  /opt/ngxlog/${homeurl}.error.log;#g" /etc/nginx/conf.d/work.conf

sed -i "s#^sso.url=.*#sso.url=http://${ssourl}#g" /opt/bigops/config/bigops.properties
sed -i "s#^home.url=.*#home.url=http://${homeurl}#g" /opt/bigops/config/bigops.properties

echo -e "please input db host >\c"
read dbhost

echo -e "please input db port >\c"
read dbport

echo -e "please input db name >\c"
read dbname

echo -e "please input db user >\c"
read dbuser

echo -e "please input db pass >\c"
read dbpass

dbhost=`echo "$dbhost"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbport=`echo "$dbport"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbname=`echo "$dbname"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbuser=`echo "$dbuser"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`
dbpass=`echo "$dbpass"|sed 's/^[ ]*//g'|sed 's/[ ]*$//g'`

sed -i "s#^spring.datasource.url=.*#spring.datasource.url=jdbc:mysql://${dbhost}:${dbport}/${dbname}\?useSSL=false\&useUnicode=true\&autoReconnect=true\&characterEncoding=UTF-8#g" /opt/bigops/config/bigops.properties
sed -i "s#^spring.datasource.username=.*#spring.datasource.username=${dbuser}#g" /opt/bigops/config/bigops.properties
sed -i "s#^spring.datasource.password=.*#spring.datasource.password=${dbpass}#g" /opt/bigops/config/bigops.properties

mysqladmin -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} drop ${dbname}
mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} -e "create database ${dbname}" 2>/dev/null
mysql -u${dbuser} -p${dbpass} -h${dbhost} -P${dbport} ${dbname} </opt/bigops/install/mysql/bigops-1.0.0.sql 2>/dev/null

if [ $? == 0 ];then
    /bin/sh /opt/bigops/bin/restart.sh
fi

