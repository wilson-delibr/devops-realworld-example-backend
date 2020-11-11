#!/usr/bin/env bash

set -e
set -x
imagename=${IMAGENAME:-todo}
version=${GO_PIPELINE_LABEL:-dev}

repository_prefix=${REPOSITORY_PREFIX}

full_imagename=${repository_prefix}/${imagename}:${version}

mode="--fast"
if [ $# -eq 1 ]; then
    mode=$1
fi

# Fetch the image
gcloud docker -- pull ${full_imagename}

# Instant
if [ "${mode}" = "--fast" ]; then
# Hardcoded parts to work on a Go agent running in docker cloud
    docker_id=`docker ps | grep $HOSTNAME | grep -v POD | awk '{print $1}'`
    cred_dir=`dirname ${GOOGLE_APPLICATION_CREDENTIALS}`
    host_vol_dir=`docker inspect  $docker_id  | grep $cred_dir | grep /var/lib/kub | sed s/\"//g | awk -F: '{print $1}'`
    docker run --rm -v ${host_vol_dir}:${cred_dir} -e GOOGLE_DATASTORE_NAMESPACE="${imagename}${mode}${version}" -e GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS} ${full_imagename} ./runtest --fast
fi
