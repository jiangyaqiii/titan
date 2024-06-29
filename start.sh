#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 检查并安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 节点安装功能
function install_node() {
    install_nodejs_and_npm
    install_pm2

    # 设置变量


    # 更新和安装必要的软件
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

    # 安装 Go
        sudo rm -rf /usr/local/go
        curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
        source $HOME/.bash_profile
        go version

    # 安装所有二进制文件
    cd $HOME
    git clone https://github.com/nezha90/titan.git
    cd titan
    go build ./cmd/titand
    cp titand /usr/local/bin

    # 配置titand
    export MONIKER="My_Node"
    titand init $MONIKER --chain-id titan-test-1
    titand config node tcp://localhost:53457

    # 获取初始文件和地址簿
    wget https://raw.githubusercontent.com/nezha90/titan/main/genesis/genesis.json
    mv genesis.json ~/.titan/config/genesis.json

    # 配置节点
    SEEDS="bb075c8cc4b7032d506008b68d4192298a09aeea@47.76.107.159:26656"
    PEERS=""
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.titan/config/config.toml

    wget https://raw.githubusercontent.com/nezha90/titan/main/addrbook/addrbook.json
    mv addrbook.json ~/.titan/config/addrbook.json

    # 配置裁剪
    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.titan/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.titan/config/app.toml
    sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.titan/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.titan/config/app.toml
    sed -i -e 's/max_num_inbound_peers = 40/max_num_inbound_peers = 100/' -e 's/max_num_outbound_peers = 10/max_num_outbound_peers = 100/' $HOME/.titan/config/config.toml
    sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025uttnt\"/;" ~/.titan/config/app.toml

    # 配置端口
    node_address="tcp://localhost:53457"
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:53458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:53457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:53460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:53456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":53466\"%" $HOME/.titan/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:53417\"%; s%^address = \":8080\"%address = \":53480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:53490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:53491\"%; s%:8545%:53445%; s%:8546%:53446%; s%:6065%:53465%" $HOME/.titan/config/app.toml
    echo "export TITAN_RPC_PORT=$node_address" >> $HOME/.bash_profile
    source $HOME/.bash_profile   

    pm2 start titand -- start && pm2 save && pm2 startup

    # 下载快照
    titand tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
    curl https://snapshots.dadunode.com/titan/titan_latest_tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.titan/data
    mv $HOME/.titan/priv_validator_state.json.backup $HOME/.titan/data/priv_validator_state.json

    # 使用 PM2 启动节点进程

    pm2 restart artelad
    

    echo '====================== 安装完成,请退出脚本后执行 source $HOME/.bash_profile 以加载环境变量 ==========================='
    
}
install_node
