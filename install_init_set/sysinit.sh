#!/bin/bash
yum -y install wget vim net-tool bash-completion net-tools && \
source /etc/profile.d/bash_completion.sh && \
yum -y install lrzsz.x86_64 gcc gcc-c++ && \
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/CentOS-epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache

wget http://mirrors.aliyun.com/repo/Centos-7.repo
wget http://mirrors.aliyun.com/repo/epel-7.repo
