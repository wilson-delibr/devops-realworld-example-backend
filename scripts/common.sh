#!/usr/bin/env bash

# Install docker client. Addresses the error "Docker not installed". "setup_remote_docker" is not enough
function installDockerClient() {
  set -xVER="17.03.1-ce"
  curl -L -o /tmp/docker-$VER.tgz https://get.docker.com/builds/Linux/x86_64/docker-$VER.tgz
  tar -xz -C /tmp -f /tmp/docker-$VER.tgz
  mv /tmp/docker/* /usr/bin
  
}

# Authenticate with a service account, set GCP project and compute zone
function gcpAuthenticate() {
  googleAuth=$1
  googleProjectId=$2
  googleComputeZone=$3

  echo ${googleAuth} | base64 -i --decode > gcp-key.json
  gcloud auth activate-service-account --key-file gcp-key.json
  gcloud --quiet config set project ${googleProjectId}
  gcloud --quiet config set compute/zone ${googleComputeZone}
}

function createTerraformConf()
{
  googleAuth=$1
  project_name=$2
  tf_creds="${HOME}/gcp-key.json"
  echo ${googleAuth} | base64 -i --decode > ${tf_creds}
  cat > terraform-infrastructure-live/gce_account/terraform.tfvars <<EOF
  // Created by scripts/bootstrap.sh
terragrunt = {
  remote_state {
    backend = "gcs"
    config {
      bucket = "${project_name}"
      project = "${project_name}"
      path   = "\${path_relative_to_include()}/terraform.tfstate"
      credentials = "${tf_creds}"
    }
  }
  terraform = {
    extra_arguments "account_vars" {
      commands = ["\${get_terraform_commands_that_need_vars()}"]

      required_var_files = [
        "\${get_parent_tfvars_dir()}/terraform.tfvars"

      ]
    }
  }
}
google_project = "${project_name}"
google_keyfile = "${tf_creds}"
EOF

  
  
}
# Authenticate to a GKE cluster
function gkeClustersGetCredentials() {
  googleClusterName=$1
  gcloud --quiet container clusters get-credentials ${googleClusterName}
}

# Prints names of all pods in the 'Running'
function getPodNamesInStateRunning() {
  namespace=$1
  label=$2

  kubectl -n ${namespace} get pods -l name=${label} -o go-template --template '{{range .items}}{{.metadata.name}}{{" "}}{{.status.phase}}{{"\\n"}}{{end}}'|grep Running|awk '{print $1}'
}

# Prints pod name of running pod with given label. Waits until there is exactly one pod in state 'Running'
function getPodName() {
  namespace=$1
  label=$2

  podName=''
  n=0
  while true; do
    if [ -n "${podName}" ]; then
      # podName contains something
      if [[ !("${podName}" == *$'\n'*) ]]; then
        # podName does not contain multiple rows (pods)
        echo $podName
        return
      fi
    fi

    podName=`getPodNamesInStateRunning ${namespace} ${label}`
    if [ $? -gt 0 ]; then
      return # No pods are running
    fi
    if [ -z "${podName}" ]; then
      return # No pods are running
    fi

    n=$((n+1))
    if [ $n -gt 60 ]; then
      (>&2 echo "Timeout waiting for a single or no pod running, podName ${podName}")
      return
    fi
    sleep 1
  done
}

# Delete all deployments in a namespace
function deleteDeployments() {
  namespace=$1
  (>&2 echo "Deleting deployments in ${namespace}")
  kubectl -n ${APP_NAME}-it delete deployment `kubectl -n ${namespace} get deployments -o jsonpath={.items[*].metadata.name}`
}
