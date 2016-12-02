#!/bin/bash
echo '****************************************************************************'
echo '     initialize_datastructures.sh                     '
echo '            by niuren.zhu                     '
echo '               2016.10.26                     '
echo '  说明：                                  '
echo '  1. 遍历目录WEB_INF/lib/ibcp.*.jar包，通过btulz创建数据结构。      '
echo '  2. 数据库的配置信息读自各个模块的app.xml。                '
echo '  3. 参数1，工作目录，如：tomcat/webapps/。                 '
echo '****************************************************************************'
# 检查JAVA运行环境
if [ ! -e "${JAVA_HOME}/bin/java" ];then
  echo not found java.
  exit 1
fi;
# 定义变量
# ibcp释放目录
DEPLOY_FOLDER=$1
# ibcp工具目录,脚本所在目录
TOOLS_FOLDER=$(echo `dirname $0`)
TOOLS_TRANSFORM=${TOOLS_FOLDER}/btulz.transforms.core-0.1.0.jar
# 判断工具是否存在
if [ ! -e "${TOOLS_TRANSFORM}" ];then
  echo not found btulz.transforms, in [${TOOLS_TRANSFORM}].
  exit 1
fi;

# 数据库信息
CompanyId=CC
MasterDbType=
MasterDbServer=
MasterDbPort=
MasterDbSchema=
MasterDbName=
MasterDbUserID=
MasterDbUserPassword=
# 获取属性值
function getAttr()  
{  
   ATTR_PAIR=${1#*$2=\"}  
   echo "${ATTR_PAIR%%\"*}"  
} 
# 从app.xml中获取配置项，参数1：配置文件
function getConfigValue()
{
   CONFIG_FILE=$1;
   local IFS=\>

   while read -d \< ENTITY CONTENT
     do     
       TAG_NAME=${ENTITY%% *}
       ATTRIBUTES=${ENTITY#* }
       if [[ $TAG_NAME == "add" ]]
         then
           key=`getAttr ${ATTRIBUTES} "key"`
           value=`getAttr ${ATTRIBUTES} "value"`
           # echo $key=$value
           eval "${key}='${value}'"
        fi
     done < ${CONFIG_FILE}
     
# 修正参数值
  MasterDbType=$(echo $MasterDbType | tr '[A-Z]' '[a-z]')
# 数据库架构修正
  if [ "${MasterDbType}" == "mssql" ];then
    if [ "${MasterDbSchema}" == "" ];then MasterDbSchema=dbo; fi;
  else
    MasterDbSchema=
  fi;
# 数据库端口修正
  if [ "${MasterDbType}" == "mssql" ];then
    if [ "${MasterDbPort}" == "" ];then MasterDbPort=1433; fi;
  fi;
  if [ "${MasterDbType}" == "mysql" ];then
    if [ "${MasterDbPort}" == "" ];then MasterDbPort=3306; fi;
  fi;
  if [ "${MasterDbType}" == "pgsql" ];then
    if [ "${MasterDbPort}" == "" ];then MasterDbPort=5432; fi;
  fi;
  if [ "${MasterDbType}" == "hana" ];then
    if [ "${MasterDbPort}" == "" ];then MasterDbPort=30015; fi;
  fi;
}
# 创建数据结构
function createDS()  
{
# 参数1，使用的jar包
  JarFile=$1;
  COMMOND="java -Djava.ext.dirs=${TOOLS_FOLDER}/lib -jar \
    ${TOOLS_TRANSFORM} dsJar \
    -DsTemplate=ds_${MasterDbType}_ibas_classic.xml \
    -JarFile=${JarFile} \
    -SqlFilter=sql_${MasterDbType} \
    -Company=${CompanyId} \
    -DbServer=${MasterDbServer} \
    -DbPort=${MasterDbPort} \
    -DbSchema=${MasterDbSchema} \
    -DbName=${MasterDbName} \
    -DbUser=${MasterDbUserID} \
    -DbPassword=${MasterDbUserPassword};"
  echo exec: ${COMMOND};
  eval $(echo ${COMMOND});
} 
# 未提供工作目录，尝试取tomcat/webapps/目录
if [ "${DEPLOY_FOLDER}" == "" ];then
  if [ "${CATALINA_HOME}" != "" ];then DEPLOY_FOLDER=${CATALINA_HOME}/webapps; fi;  
fi;
# 没有目录则使用当前目录
if [ "${DEPLOY_FOLDER}" == "" ];then DEPLOY_FOLDER=$PWD; fi;

echo 开始分析${DEPLOY_FOLDER}目录下数据
# 检查是否存在模块说明文件，此文件描述模块初始化顺序。
if [ ! -e "${DEPLOY_FOLDER}/ibcp.release.txt" ]
then
  ls -l "${DEPLOY_FOLDER}" | awk '/^d/{print $NF}' > "${DEPLOY_FOLDER}/ibcp.release.txt"
fi
while read folder
do
  echo --${folder}
# 读取配置信息，用配置文件刷新变量
    FILE_APP=${DEPLOY_FOLDER}/${folder}/WEB-INF/app.xml
    if [ -e "${FILE_APP}" ]; then
      getConfigValue ${FILE_APP};
    fi;
# 使用模块目录jar包
    if [ -e "${DEPLOY_FOLDER}/${folder}/WEB-INF/lib" ]
    then
      for file in `ls "${DEPLOY_FOLDER}/${folder}/WEB-INF/lib" | grep ibcp\.${folder}\-.`
      do
        echo ----${file}
        createDS ${DEPLOY_FOLDER}/${folder}/WEB-INF/lib/${file};      
        echo ----
      done
    fi;
# 使用共享目录jar包
    if [ -e "${CATALINA_HOME}/lib" ]
    then
      for file in `ls "${CATALINA_HOME}/lib" | grep ibcp\.${folder}\-.`
      do
        echo ----${file}
        createDS ${CATALINA_HOME}/lib/${file};      
        echo ----
      done
    fi;
    echo --
  done < "${DEPLOY_FOLDER}/ibcp.release.txt" | sed 's/\r//g'
echo 操作完成
