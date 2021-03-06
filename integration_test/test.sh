#!/bin/bash
set -e
IMAGE_NAME=imagecleanup_test

export RUST_LOG=debug

failTest(){
        echo Test failed. Printing list of remaining images...
        docker images $IMAGE_NAME
        exit 1
}

countImage(){
	docker images -q $IMAGE_NAME | wc -l
}

echo Cleaning up...
for i in {1..6}; do
	docker rmi $IMAGE_NAME:$i > /dev/null 2>&1 || true
done

echo Building test images

for i in {1..5}; do
	docker build -q --no-cache -t $IMAGE_NAME:$i .
done
docker tag $IMAGE_NAME:5 $IMAGE_NAME:6

echo
echo Test keeping all images

../target/debug/imagecleanup --numbered $IMAGE_NAME --numbered-keep 99

if [ "`countImage`" != "6" ]; then
        failTest
fi

echo
echo Testing removing all but last 2 images

../target/debug/imagecleanup --numbered $IMAGE_NAME --numbered-keep 2

if [ "`countImage`" != "3" ]; then
	failTest
fi

echo
echo Testing removing all but tagged image

docker tag $IMAGE_NAME:4 $IMAGE_NAME:keep

../target/debug/imagecleanup --numbered $IMAGE_NAME --numbered-keep 0

if [ "`countImage`" != "2" ]; then
	failTest
fi

echo
echo Testing removing all images

docker rmi $IMAGE_NAME:keep

../target/debug/imagecleanup --numbered $IMAGE_NAME --numbered-keep 0

if [ "`countImage`" != "0" ]; then
        failTest
fi

echo
echo Test passed \\o/
