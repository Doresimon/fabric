# o

## Alice

> ./network_setup.Alice.sh up > Alice.log &

## Bob

> ./network_setup.Bob.sh up > Alice.log &

## 启动顺序

> sudo apt update
>
> sudo apt install git nodejs docker-ce docker-compose
>
> ./1.download-dockerimages.sh -c 1.3.0 -f 1.3.0
>
> // 设定组织信息, 各种名称
>
> // 1. 生成各种证书 crypto-config.yaml
>
> // 2. 生成 idemix 证书
>
> // 3. docker-compose\*\*\*.yaml 文件中替换公私钥文件路径
>
> // 4. 生成 genesis.block
>
> // 5. 生成 channel.tx
>
> // 6. 生成 \*\*\*MSPanchors.tx

> ./4.replaceOrgNameAndIP.sh Alice 10.171.5.32 Bob 10.171.5.128

> ./5.replaceOrgName.sh Alice

> docker-compose -f ./docker-compose.zookeeper.yaml up -d 2>&1
>
> docker-compose -f ./docker-compose.kafka.yaml up -d 2>&1
>
> docker-compose -f ./docker-compose.order.yaml up -d 2>&1
>
> docker-compose -f ./docker-compose.peer.yaml up -d 2>&1
>
> docker-compose -f docker-compose.ca.yaml up -d 2>&1

debug version

> docker-compose -f ./docker-compose.zookeeper.yaml up > ./log/zookeeper.log &
>
> docker-compose -f ./docker-compose.kafka.yaml up > ./log/kafka.log &
>
> docker-compose -f ./docker-compose.order.yaml up > ./log/order.log &
>
> docker-compose -f ./docker-compose.peer.yaml up > ./log/peer.log &
>
> docker-compose -f docker-compose.ca.yaml up > ./log/ca.log &
>