#!/bin/bash

if [[ $(docker ps -qf name=titan) ]]; then
    echo "titan正在运行"
else
    echo "titan未在运行"
fi
