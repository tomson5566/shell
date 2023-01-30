#!/bin/bash
for i in `jps | awk '{print $1}'`; do kill -9 $i; done

#systemctl stop docker

