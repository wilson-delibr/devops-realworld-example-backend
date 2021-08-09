#!/usr/bin/env bash

set -e

directory=`dirname $0`
source ${directory}/common.sh


imagename=${1:-todo}
version=${2:-dev}

# docker build
docker build -t ${imagename}:${version} .

# docker run tests
docker run --rm ${imagename}:${version} ./runtest
