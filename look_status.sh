#!/bin/bash

if [[ $(docker ps -qf name=titan) ]]; then
    echo "titan正在运行"
else
    echo "停止"
fi
