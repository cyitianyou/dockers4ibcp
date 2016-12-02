#!/bin/bash
echo '****************************************************************************'
echo '    build_dockerfile4all.sh                                                 '
echo '                      by niuren.zhu                                         '
echo '                           2016.10.20                                       '
echo '  说明：                                                                    '
echo '    1. 调用dockerfile4all创建镜像。                                         '
echo '    2. 镜像创建标签格式为ibcp-all:当前时间。                                '
echo '****************************************************************************'
# 定义变量
TAG=$(date +%s)

echo 开始构建ibcp全模块容器镜像
echo 镜像标签：ibcp-nginx:${TAG}
# 调用docker build
docker build --force-rm --rm --no-cache -f ./dockerfile4all -t avatech/ibcp-nginx:${TAG} ./

echo 镜像构建完成，标签：avatech/ibcp-nginx:${TAG}
