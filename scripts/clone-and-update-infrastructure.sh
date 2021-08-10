#!/usr/bin/env bash

set -e

if [ ${SHLVL} -gt 10 ]; then
    echo "To many tries"
    exit 1
fi

gitref=${1:-noref}
path=${2:-gce/europe-north1/dev/realworld-backend/fast}
infrarepo=${3:-`echo $CIRCLE_REPOSITORY_URL | awk -F'/' '{print $1}'`/devops-live-infrastructure.git}
githubaccount=${4:-`echo $CIRCLE_REPOSITORY_URL | awk -F'/' '{print $1}' | awk -F':' '{print $2}'`}

# Add github ssh key
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
fi
ssh-keyscan github.com >>~/.ssh/known_hosts
git clone ${infrarepo}
ls
find devops-live-infrastructure
cd ${path}
echo tag = \"${gitref}\" > tag.auto.tfvars
sed -i s/?ref=.*\"/?ref=${gitref}\"/ terragrunt.hcl
sed -i s/github.com\\/[^\\/]*\\//github.com\\/${githubaccount}\\// terragrunt.hcl
if [ `git diff | wc -l` -gt 0 ]; then
    git config user.email "alexander.wilson@delibr.com"
    git config user.name "AS Wilson"
    git commit -m"Automated Updated ${path} to image version ${version} and gitref ${gitref}" -a
    git push || (cd -; rm -rf devops-live-infrastructure; $0 "$@")
fi
