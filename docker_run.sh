#运行app0
###运行app0-mysql-master
echo 运行app0-master
docker run --name=app0-master -e REPLICATION_MASTER=true -e MYSQL_ROOT_PASSWORD=1q2w3e -d avatech/mysql:5.7
###运行app0-mysql-slave
echo 运行app0-slave
docker run --name=app0-slave --link=app0-master:master -e REPLICATION_SLAVE=true -e MYSQL_ROOT_PASSWORD=1q2w3e -d avatech/mysql:5.7
###运行app0-tomcat
echo 运行app0-tomcat
docker run --name=app0-tomcat --link=app0-master:master --link=app0-slave:slave -v `pwd`/conf/app0/tomcat-ibcp/ibcp:/srv/ibcp -d ibcp-all:1480575680
###运行app0-nginx
echo 运行app0-nginx
docker run --name=app0-nginx --link=app0-tomcat:tomcat -v `pwd`/conf/app0/nginx-ibcp/conf.d:/etc/nginx/conf.d -d avatech/ibcp-nginx:1480406214
#运行app1
###运行app1-master
echo 运行app1-master
docker run --name=app1-master -e REPLICATION_MASTER=true -e MYSQL_ROOT_PASSWORD=1q2w3e -d avatech/mysql:5.7
###运行app1-slave
echo 运行app1-slave
docker run --name=app1-slave --link=app1-master:master -e REPLICATION_SLAVE=true -e MYSQL_ROOT_PASSWORD=1q2w3e -d avatech/mysql:5.7
###运行app1-tomcat
echo 运行app1-tomcat
docker run --name=app1-tomcat --link=app1-master:master --link=app1-slave:slave -v `pwd`/conf/app1/tomcat-ibcp/ibcp:/srv/ibcp -d ibcp-all:1480575680
###运行app1-nginx
echo 运行app1-nginx
docker run --name=app1-nginx --link=app1-tomcat:tomcat -v `pwd`/conf/app1/nginx-ibcp/conf.d:/etc/nginx/conf.d -d avatech/ibcp-nginx:1480406214
#运行nginx-porxy
echo 运行nginx-porxy
docker run --name=nginx-porxy --link=app0-nginx --link=app1-nginx -p 80:80 -v `pwd`/conf/nginx-porxy/conf.d:/etc/nginx/conf.d -d avatech/nginx:1.11.6

