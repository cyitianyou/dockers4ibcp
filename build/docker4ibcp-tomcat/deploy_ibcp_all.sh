#!/bin/bash
echo '****************************************************************************'
echo '         deploy_ibcp_all.sh                                                 '
echo '                      by niuren.zhu                                         '
echo '                           2016.10.20                                       '
echo '  说明：                                                                    '
echo '    1. 下载ibcp所有模块并解压，默认从ibas.club:8866下载。                   '
echo '    2. 参数1，部署目录，如：tomcat根目录，所有模块释放到部署目录/webapps/。 '
echo '    3. 参数2，数据目录，各个模块数据及配置文件集中映射到此目录。            '
echo '    4. 脚本用到unzip命令，请提前安装。                                      '
echo '    5. /ibcp_packages为下载模块目录，请手工清除。                           '
echo '    6. /webapps/ibcp.release记录所以释放的文件夹名称。                      '
echo '****************************************************************************'
# 定义变量
# 释放的目录
DEPLOY_FOLDER=$1
if [ "${DEPLOY_FOLDER}" == "" ];then DEPLOY_FOLDER=$PWD; fi;
# ibcp工作目录
IBCP_WORK_FOLDER=$2
if [ "${IBCP_WORK_FOLDER}" == "" ];then IBCP_WORK_FOLDER=$PWD; fi;
# 程序包-发布服务地址
IBCP_PACKAGE_URL=http://ibas.club:8866/ibcp
# 程序包-发布服务用户名
IBCP_PACKAGE_USER=avatech/\amber
# 程序包-发布服务用户密码
IBCP_PACKAGE_PASSWORD=Aa123456
# 程序包-版本路径
IBCP_PACKAGE_VERSION=latest
# 程序包-下载目录
IBCP_PACKAGE_DOWNLOAD=${IBCP_WORK_FOLDER}/ibcp_packages/$(date +%s)
# ibcp配置目录
IBCP_CONF=${IBCP_WORK_FOLDER}/ibcp/conf
# ibcp数据目录
IBCP_DATA=${IBCP_WORK_FOLDER}/ibcp/data
# ibcp日志目录
IBCP_LOG=${IBCP_WORK_FOLDER}/ibcp/log

# 初始化环境
mkdir -p "${IBCP_PACKAGE_DOWNLOAD}"
mkdir -p "${IBCP_CONF}"
mkdir -p "${IBCP_DATA}"
mkdir -p "${IBCP_LOG}"
mkdir -p "${DEPLOY_FOLDER}/webapps"

# 下载ibcp
echo 开始下载模块，从${IBCP_PACKAGE_URL}/${IBCP_PACKAGE_VERSION}/
wget -r -np -nd -nv -P ${IBCP_PACKAGE_DOWNLOAD} --http-user=${IBCP_PACKAGE_USER} --http-password=${IBCP_PACKAGE_PASSWORD} ${IBCP_PACKAGE_URL}/${IBCP_PACKAGE_VERSION}/
# 排序
if [ ! -e "${IBCP_PACKAGE_DOWNLOAD}/ibcp.deploy.order.txt" ]; then
    ls -l "${IBCP_PACKAGE_DOWNLOAD}/*.war" | awk '//{print $NF}' >>"${IBCP_PACKAGE_DOWNLOAD}/ibcp.deploy.order.txt";
fi;
echo 开始解压模块，到目录${CATALINA_HOME}
while read file
  do
    file=${file%%.war*}.war
    echo 释放"${IBCP_PACKAGE_DOWNLOAD}/${file}"
# 修正war包的解压目录
    folder=${file##*ibcp.}
    folder=${folder%%.service*}
# 记录释放的目录到ibcp.release.txt，此文件为部署顺序说明。
    if [ ! -e "${DEPLOY_FOLDER}/webapps/ibcp.release.txt" ]; then :>"${DEPLOY_FOLDER}/webapps/ibcp.release.txt"; fi;
    grep -q ${folder} "${DEPLOY_FOLDER}/webapps/ibcp.release.txt" || echo "${folder}" >>"${DEPLOY_FOLDER}/webapps/ibcp.release.txt"
# 解压war包到目录
    unzip -o "${IBCP_PACKAGE_DOWNLOAD}/${file}" -d "${DEPLOY_FOLDER}/webapps/${folder}"
# 删除配置文件，并映射到统一位置
    if [ -e "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/app.xml" ]; then
      if [ ! -e "${IBCP_CONF}/app.xml" ]; then cp -f "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/app.xml" "${IBCP_CONF}/app.xml"; fi;
      rm -f "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/app.xml"
      ln -s "${IBCP_CONF}/app.xml" "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/app.xml"
    fi;
# 删除服务路由文件，并映射到统一位置
    if [ -e "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/service_routing.xml" ]; then
      if [ ! -e "${IBCP_CONF}/service_routing.xml" ]; then cp -f "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/service_routing.xml" "${IBCP_CONF}/service_routing.xml"; fi;
      rm -f "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/service_routing.xml"
      ln -s "${IBCP_CONF}/service_routing.xml" "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/service_routing.xml"
    fi
# 映射日志文件夹到统一位置
    if [ -e "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/log" ]; then rm -rf "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/log"; fi;
    ln -s -d "${IBCP_LOG}" "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/"
# 集中共享jar包
    if [ -e "${DEPLOY_FOLDER}/lib/" ]
    then
# 复制模块jar包到tomcat的lib目录
      cp -n "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/lib/"*.jar "${DEPLOY_FOLDER}/lib/";
# 清除tomcat的lib已经存在的jar包
      rm -f "${DEPLOY_FOLDER}/webapps/${folder}/WEB-INF/lib/"*.jar;
    fi;
  done < "${IBCP_PACKAGE_DOWNLOAD}/ibcp.deploy.order.txt" | sed 's/\r//g';
echo 操作完成
