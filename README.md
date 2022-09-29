# Terraform EKS and EFS driver.
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)
![Jenkins](https://img.shields.io/badge/jenkins-lts-white.svg?style=flat&logo=jenkins)
[![jenkins con](https://img.shields.io/badge/jenkins-casc-red.svg?style=flat&logo=jenkins&logoColor=white)](https://plugins.jenkins.io/configuration-as-code/)


In this repository there is an example of how to deploy a cluster of eks and efs drivers so that the cluster has control of the life cycle

## EKS deploy

### variables:
> all variables are used in this step are in eks-cluster/variables. tf



```bash
export KUBE_CONFIG_PATH=/path/to/kubeconfig
aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text

```

## Jenkins instance
Jenkins instance on kubernetes cluster with efs persistent volume claim. Likewise, the jenkins instance can perform the deployment of pods as agents for the execution of jobs and at the end of the task it must eliminate them.

### Resources
- Persistent Volume Claim: This persistent volume claim requests storage of type `efs-sc` which is the storage class previously configured in the kubernetes cluster.
- ConfigMaps:
    - jenkins-plugin: In this configmap the data contained in the externals/plugins.txt file will be loaded to be used by the init container to install said plugins.
    - jenkins-casc-config: In this configmap the data contained in the externals/casc.yaml file will be loaded to be used by jenkins-master instance for run bootstrap configuration with the help of plugin [jenkins configuration as a code](https://plugins.jenkins.io/configuration-as-code/) Here is an example of implementing it -> [github/jenkinsci/configuration-as-code-plugin](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/demos/embedded-userdatabase/README.md)
- Deployment: Is the deployment for the master instance of jenkins, it consists of two containers, the init container to install the plugin dependencies and the main container that shares the pvc with the init container for the jenkins-home directory `/var/jenkins_home` where previously The plugins were installed, it also mounts the value of configmap as a volume to create the yaml file with the configuration for the user and other security configuration related to the jenkins instance.
- Service Account: Jenkins needs to access the Kubernetes API, therefore you need to properly setup a Kubernetes Service Account and Role in order to represent Jenkins access for the Kubernetes API.
- Role: Create required access Role and RoleBinding for jenkins-master in jenkins namespace
    - Rules:
        - resources: ["pods"]
            - verbs: ["create","delete","get","list","patch","update","watch"]
        - resources: ["pods/exec"]
            - verbs: ["create","delete","get","list","patch","update","watch"]
        - resources: ["pods/log"]
            - verbs: ["get","list","watch"]
        - resources: ["events"]
            - verbs: ["get","list","watch"]
        - resources: ["secrets"]
            - verbs: ["get"]
    
> In jenkins 
Kubernetes API server address: kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " "
Kubernetes server CA certificate key: kubectl get secret $(kubectl get sa jenkins-master -n jenkins -o jsonpath={.secrets[0].name}) -n jenkins -o jsonpath={.data.'ca\.crt'} | base64 --decode