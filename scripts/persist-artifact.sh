#!/usr/bin/env bash

set -e

directory=`dirname $0`
source ${directory}/common.sh


imagename=${1:-todo}
version=${2:-dev}

repository_prefix=${3}

# Retag image
docker tag ${imagename}:${version} ${repository_prefix}/${imagename}:${version}

# Push image
gcloud docker -- push ${repository_prefix}/${imagename}:${version}

# Delete local image
docker rmi ${imagename}:${version} ${repository_prefix}/${imagename}:${version}