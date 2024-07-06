#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
echo "ulimit -v 640000;" >> ~/.bashrc

function install_node() {

# 读取加载身份码信息
read -p "输入你的身份码: " id

apt update -y

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    echo "未检测到 Docker，正在安装..."
    apt-get install ca-certificates curl gnupg lsb-release -y
    
    # 安装 Docker 最新版本
    apt-get install docker.io -y
else
    echo "Docker 已安装。"
fi

# 拉取Docker镜像
docker pull nezha123/titan-edge:1.6_amd64

# 创建用户指定数量的容器
current_rpc_port=30000

storage_path="$PWD/titan_storage"

# 确保存储路径存在
mkdir -p "$storage_path"

# 运行容器，并设置重启策略为always
container_id=$(docker run -d --restart always -v "$storage_path:/root/.titanedge/storage" --name "titan" --net=host  nezha123/titan-edge:1.6_amd64)

echo "节点 titan 已经启动 容器ID $container_id"

sleep 30

# 修改宿主机上的config.toml文件以设置StorageGB值和端口
docker exec $container_id bash -c "\
    sed -i 's/^[[:space:]]*#StorageGB = .*/StorageGB = 30/' /root/.titanedge/config.toml && \
    sed -i 's/^[[:space:]]*#ListenAddress = \"0.0.0.0:1234\"/ListenAddress = \"0.0.0.0:$current_rpc_port\"/' /root/.titanedge/config.toml && \
    echo '容器 titan 的存储空间设置为 30 GB，RPC 端口设置为 $current_rpc_port'"

# 重启容器以让设置生效
docker restart $container_id

# 进入容器并执行绑定命令
docker exec $container_id bash -c "\
    titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
echo "节点 titan 已绑定."

echo "==============================所有节点均已设置并启动==================================="

}
install_node
