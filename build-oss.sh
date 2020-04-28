#!/bin/bash


OSS="oss-"
KIBANA_VERSION=7.3.2



rm -rf kibana
rm -rf node

if [ ! -f "kibana-${OSS}${KIBANA_VERSION}-linux-x86_64.tar.gz" ]; then
    wget https://artifacts.elastic.co/downloads/kibana/kibana-${OSS}${KIBANA_VERSION}-linux-x86_64.tar.gz
fi

tar zxvf kibana-${OSS}${KIBANA_VERSION}-linux-x86_64.tar.gz 
mv kibana-${KIBANA_VERSION}-linux-x86_64 kibana


if [ ! -f "node-v10.15.2-linux-arm64.tar" ]; then
    wget https://nodejs.org/dist/v10.15.2/node-v10.15.2-linux-arm64.tar.xz
    xz -d node-v10.15.2-linux-arm64.tar.xz
fi
tar xvf node-v10.15.2-linux-arm64.tar 
mv node-v10.15.2-linux-arm64 node

if [ ! -f "phantomjs_2.1.1_arm64.tgz" ]; then
    wget https://github.com/fg2it/phantomjs-on-raspberry/releases/download/v2.1.1-jessie-stretch-arm64/phantomjs_2.1.1_arm64.tgz
fi

tar zxvf phantomjs_2.1.1_arm64.tgz 
mv phantomjs kibana/node_modules/@elastic/nodegit

rm -rf kibana/node
mv node  kibana/

docker build -t kibana-oss:${KIBANA_VERSION} . -f Dockerfile.oss

rm -f node-v10.15.2-linux-arm64.tar
rm -rf node
rm -rf kibana 
