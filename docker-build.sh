#!/bin/sh

. ./.docker

CMD_ENV=""
CMD_LINK=""

if [ -e .env ]; then
	for dockerenv in `cat .env`;do
		CMD_ENV="$CMD_ENV --env $dockerenv"
	done
fi

if [ -e .link ]; then
	for dockerlink in `cat .link`;do
		CMD_LINK="$CMD_LINK --link $dockerlink"
	done
fi

echo "Update source"
git pull origin master
echo "Update source done"

echo "Download npm packages"
docker run -ti --rm -v $PWD:/app ajnasz/node-npm-installer
echo "Download npm packages done"

if [ ! -z "`docker ps | grep $CONTAINER_NAME`" ];then
	echo "Stop current container"
	sudo systemctl stop $SERVICE_NAME
	echo "Stop current container done"
fi

if [ ! -z "`docker ps -a | grep $CONTAINER_NAME`" ];then
	echo "Remove current container"
	docker rm $CONTAINER_NAME
	echo "Remove current container done"
fi

if [ ! -z "`docker images | grep $IMAGE_NAME`" ];then
	echo "Remove current image"
	docker rmi $IMAGE_NAME
	echo "Remove current image done"
fi

echo "Build new container"
docker build -t $IMAGE_NAME .
echo "Build new container done"

cmd=`cut -d ' ' -f 2- Procfile`

echo "Create new container"
# echo docker create -ti --name $CONTAINER_NAME $CMD_LINK $CMD_ENV $IMAGE_NAME $cmd
docker create -m="70m" -ti --name $CONTAINER_NAME $CMD_LINK $CMD_ENV $IMAGE_NAME $cmd
echo "Create new container done"

echo "Start new container"
sudo systemctl start  $SERVICE_NAME
echo "Start new container done"

sudo rm -rf node_modules
