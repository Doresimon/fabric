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
