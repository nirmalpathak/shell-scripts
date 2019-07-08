#!/bin/bash
#
# Script based on https://jeremievallee.com/2018/05/28/kubernetes-rbac-namespace-user.html
#
###################################################################
# Date:     2019/07/08
# Author:   Nirmal Pathak
# Web:      https://technirmal.wordpress.com/about/
#
# Program:
#   Create Service Account (User) on Kuberenetes cluster namespace.
#
###################################################################
#
#
namespace=$1
username=$2

if [ "$#" -ne 2 ]; then
	echo "NAMESPACE & USER_NAME as arguments are required."
	echo "Use "$(basename "$0")" NAMESPACE" "USER_NAME";
	exit 1;
fi

echo "---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $namespace-$username
  namespace: $namespace
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $namespace-$username-limited-access
  namespace: $namespace
rules:
- apiGroups: ['', 'extensions', 'apps']
  resources: ['*']
  verbs: ["get", "list", "watch"]
- apiGroups: ['batch']
  resources:
  - jobs
  - cronjobs
  verbs: ["get", "list", "watch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: $namespace-$username-view
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: $namespace-$username
  namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $namespace-$username-limited-access" > $username.yaml
#  name: $namespace-$username-limited-access" | kubectl apply -f -
kubectl create -f $username.yaml
#
tokenName=$(kubectl get sa $namespace-$username -n $namespace -o 'jsonpath={.secrets[0].name}')
token=$(kubectl get secret $tokenName -n $namespace -o "jsonpath={.data.token}" | base64 -D)
certificate=$(kubectl get secret $tokenName -n $namespace -o "jsonpath={.data['ca\.crt']}")

context_name="$(kubectl config current-context)"
cluster_name="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"${context_name}\")].context.cluster}")"
server_name="$(kubectl config view -o "jsonpath={.clusters[?(@.name==\"${cluster_name}\")].cluster.server}")"


echo "---
apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: $certificate
    server: $server_name
  name: my-cluster

users:
- name: $namespace-$username
  user:
    as-user-extra: {}
    client-key-data: $certificate
    token: $token

contexts:
- context:
    cluster: my-cluster
    namespace: $namespace
    user: $namespace-$username
  name: $namespace

current-context: $namespace" > kubeconfig-$username

echo "$namespace-$username's kubeconfig was created into `pwd`/kubeconfig-$username"
echo "If you want to test execute this command \`KUBECONFIG=`pwd`/kubeconfig-$username kubectl get po\`"
