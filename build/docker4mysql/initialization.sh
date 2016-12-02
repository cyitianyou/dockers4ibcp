#!/bin/bash
set -m

VOLUME_HOME="/var/lib/mysql"
CONF_FILE="/etc/mysql/conf.d/my.cnf"
LOG="/var/log/mysql/error.log"

# Set permission of config file
chmod 644 ${CONF_FILE}
chmod 644 /etc/mysql/conf.d/mysqld_charset.cnf

service mysql start
echo `service mysql status`
# Main
if [ ${REPLICATION_MASTER} == "**False**" ]; then
    unset REPLICATION_MASTER
fi

if [ ${REPLICATION_SLAVE} == "**False**" ]; then
    unset REPLICATION_SLAVE
fi

mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock)
if [ ! -z "${MYSQL_ROOT_PASSWORD}" ]; then
    mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
fi

# Set MySQL REPLICATION - MASTER
if [ -n "${REPLICATION_MASTER}" ]; then
    echo "=> Configuring MySQL replication as master (1/2) ..."
    if [ ! -f /replication_set.1 ]; then
        RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
        echo "=> Writting configuration file '${CONF_FILE}' with server-id=${RAND}"
        sed -i "s/^#server-id.*/server-id = ${RAND}/" ${CONF_FILE}
        sed -i "s/^#log-bin.*/log-bin = mysql-bin/" ${CONF_FILE}
        touch /replication_set.1
    else
        echo "=> MySQL replication master already configured, skip"
    fi
fi

# Set MySQL REPLICATION - MASTER
if [ -n "${REPLICATION_MASTER}" ]; then
    echo "=> Configuring MySQL replication as master (2/2) ..."
    if [ ! -f /replication_set.2 ]; then
        echo "=> Creating a log user ${REPLICATION_USER}:${REPLICATION_PASS}"        
        echo "${mysql[@]} -e \"CREATE USER '${REPLICATION_USER}'@'%' IDENTIFIED BY '${REPLICATION_PASS}'\""
        ${mysql[@]} -e "CREATE USER '${REPLICATION_USER}'@'%' IDENTIFIED BY '${REPLICATION_PASS}'"
        ${mysql[@]} -e "GRANT REPLICATION SLAVE ON *.* TO '${REPLICATION_USER}'@'%'"
        ${mysql[@]} -e "reset master"
        echo "=> Done!"
        touch /replication_set.2
    else
        echo "=> MySQL replication master already configured, skip"
    fi
fi

# Set MySQL REPLICATION - SLAVE
if [ -n "${REPLICATION_SLAVE}" ]; then
    echo "=> Configuring MySQL replication as slave (1/2) ..."
    echo "MASTER_ADDR=${MASTER_ADDR}"
    echo "MASTER_PORT=${MASTER_PORT}"
    if [ -n "${MASTER_ADDR}" ] && [ -n "${MASTER_PORT}" ]; then
        if [ ! -f /replication_set.1 ]; then
            RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
            echo "=> Writting configuration file '${CONF_FILE}' with server-id=${RAND}"
            sed -i "s/^#server-id.*/server-id = ${RAND}/" ${CONF_FILE}
            sed -i "s/^#log-bin.*/log-bin = mysql-bin/" ${CONF_FILE}
                #从库使用MyISAM引擎
            sed -i "s/^#default-storage-engine.*/default-storage-engine = MyISAM/" ${CONF_FILE}
            service mysql restart
            touch /replication_set.1
        else
            echo "=> MySQL replication slave already configured, skip"
        fi
    else
        echo "=> Cannot configure slave, please link it to another MySQL container with alias as 'mysql'"
        exit 1
    fi
fi

# Set MySQL REPLICATION - SLAVE
if [ -n "${REPLICATION_SLAVE}" ]; then
    echo "=> Configuring MySQL replication as slave (2/2) ..."
    if [ -n "${MASTER_ADDR}" ] && [ -n "${MASTER_PORT}" ]; then
        if [ ! -f /replication_set.2 ]; then
            echo "=> Setting master connection info on slave"
            ${mysql[@]} -e "CHANGE MASTER TO MASTER_HOST='${MASTER_ADDR}',MASTER_USER='${REPLICATION_USER}',MASTER_PASSWORD='${REPLICATION_PASS}',MASTER_PORT=${MASTER_PORT}, MASTER_CONNECT_RETRY=30"
            ${mysql[@]} -e "start slave"
            echo "=> Done!"
            touch /replication_set.2
        else
            echo "=> MySQL replication slave already configured, skip"
        fi
    else
        echo "=> Cannot configure slave, please link it to another MySQL container with alias as 'mysql'"
        exit 1
    fi
fi
${mysql[@]} -e "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'"
${mysql[@]} -e "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION "
${mysql[@]} -e "FLUSH PRIVILEGES"
service mysql restart
tail -f $LOG
fg

