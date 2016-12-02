#!/bin/bash
echo '****************************************************************************'
echo '    build_dockerfile4all.sh                                                 '
echo '                      by john.chen                                        '
echo '                           2016.11.29                                       '
echo '  说明：                                                                    '
echo '    1. 调用dockerfile创建镜像。                                         '
echo '    2. 镜像创建标签格式为avatech/nginx:1.11.6。                                '
echo '****************************************************************************'

echo 开始构建nginx容器镜像
echo 镜像标签：avatech/nginx:1.11.6
# 调用docker build
docker build --force-rm --rm --no-cache -f ./dockerfile -t avatech/nginx:1.11.6 ./

echo 镜像构建完成，标签：avatech/nginx:1.11.6
