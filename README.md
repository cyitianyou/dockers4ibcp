# dockers4ibcp

### Docker Images
* 使用基础镜像 docker.io/debian:jessie 、 docker.io/mysql:5.7  、 docker.io/tomcat:8.5-jre8

### avatech/nginx:1.11.6 
* 使用官方dockerfile后添加wget和unzip
* /build/docker4porxy-nginx/build_dockerfile4all.sh

### avatech/ibcp-nginx:时间戳
* 基于avatech/nginx:1.11.6 添加ibcp网站文件
* /build/docker4ibcp-nginx/build_dockerfile4all.sh

### ibcp-all:时间戳 
* 基于docker.io/tomcat:8.5-jre8 添加ibcp网站文件,ibcp配置,日志,上传文件放在${IBCP_HOME}文件夹
* /build/docker4ibcp-tomcat/build_dockerfile4all.sh

### avatech/mysql:5.7
* 基于docker.io/mysql:5.7 
* /build/docker4mysql/build_dockerfile4all.sh
* docker run时可通过-e指定环境变量,自动配置主从库,其中主库使用INNODB引擎,从库使用MyISAM引擎
* 添加环境变量
*    REPLICATION_MASTER(标记是否为主库)、REPLICATION_SLAVE是否为从库；两者互斥，优先处理REPLICATION_MASTER
*    REPLICATION_USER、REPLICATION_PASS为主从库之间同步所需要的用户名密码，主从库创建时应保持一致，默认值为manager 、 avatech
*    MASTER_ADDR、MASTER_PORT 为设置从库时指定的主库地址和端口，默认值为 master 、 3306 创建从库时使用--link=主库容器:master即可使用默认值
*    MYSQL_ROOT_PASSWORD指定root用户的密码,从基础镜像中继承
