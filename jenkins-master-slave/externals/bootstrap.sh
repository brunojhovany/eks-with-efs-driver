#!/bin/bash
# this script spec this variables 
# - KUBECONFIG
# - JENKINS_ADMIN_PASSWORD
set -x 

POD=$(kubectl get pod -l app=jenkins-master -n jenkins -o jsonpath="{.items[0].metadata.name}")

kubectl cp externals/jenkins.sh jenkins/$POD:/tmp/jenkins.sh
kubectl -n jenkins exec -ti $POD -- chmod +x /tmp/jenkins.sh

HASHED_ADMIN_PASSWORD=$(python3 externals/hash_password.py ${JENKINS_ADMIN_PASSWORD} 2>&1)

kubectl -n jenkins exec -ti $POD -- bash -c "export JENKINS_ADMIN_PASSWORD=$JENKINS_ADMIN_PASSWORD && export HASHED_ADMIN_PASSWORD=$HASHED_ADMIN_PASSWORD && /tmp/jenkins.sh"