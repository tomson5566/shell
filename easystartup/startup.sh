#!/bin/bash
cd /root/docker-compose/mysql8 && docker-compose up -d
cd /root/docker-compose/redis/ && docker-compose up -d
cd /root/nacos-docker-master/example/ && docker-compose up -d

