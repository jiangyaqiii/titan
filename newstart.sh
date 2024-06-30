echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
source ~/.bashrc
#安装依赖包
sudo apt-get update && apt-get install jq build-essential snapd -y
sudo snap install --classic go
sudo apt install git -y

#安装titan-cli
git clone https://github.com/nezha90/titan.git

cd titan
go build ./cmd/titand

cp titand /usr/local/bin

#初始化titan
export MONIKER="My_Node"
titand init $MONIKER --chain-id titan-test-1

#配置网络连接和创世文件
wget https://raw.githubusercontent.com/nezha90/titan/main/genesis/genesis.json
mv genesis.json ~/.titan/config/genesis.json

sed -i 's/seeds = ""/seeds = "bb075c8cc4b7032d506008b68d4192298a09aeea@47.76.107.159:26656"/g' $HOME/.titan/config/config.toml

wget https://raw.githubusercontent.com/nezha90/titan/main/addrbook/addrbook.json
mv addrbook.json ~/.titan/config/addrbook.json

sed -i 's/minimum-gas-prices = "0stake"/minimum-gas-prices = "0.0025uttnt"/g' $HOME/.titan/config/app.toml

echo '[Unit]
Description=Titan Daemon
After=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/titand start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/titan.service

sudo systemctl enable titan.service
sudo systemctl start titan.service
