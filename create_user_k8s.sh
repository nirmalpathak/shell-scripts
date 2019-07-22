###############################################################################
# Date:     2019/07/21
# Author:   Nirmal Pathak
# Web:      https://technirmal.wordpress.com/about/
#
# Program:
#   Create Non-Privileged users on Kuberenetes cluster in specific namespace.
#
###############################################################################
#!/bin/bash
NAME_SPACE=$1
USER_NAME=$2

if [ "$#" -ne 2 ]; then
        echo "The USER_NAME as arguments is missing."
        echo "Use "$(basename "$0")" 'NAMESPACE' 'USER_NAME'";
        exit 1;
fi


openssl genrsa -out $USER_NAME.key 2048

openssl req -new -key $USER_NAME.key -out $USER_NAME.csr -subj "/CN=$USER_NAME/O=CDE"

openssl x509 -req -in $USER_NAME.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $USER_NAME.crt -days 730

USER_CERT=$(base64 $USER_NAME.crt)
USER_KEY=$(base64 $USER_NAME.key)

#NAME_SPACE='auth-test'

echo "---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USER_NAME-binding
  NAME_SPACE: $NAME_SPACE
subjects:
- kind: User
  name: $USER_NAME
  apiGroup: 'rbac.authorization.k8s.io'
roleRef:
  kind: Role
  name: $NAME_SPACE-limited-access
  apiGroup: 'rbac.authorization.k8s.io'
---" > $USER_NAME-role-binding.yaml

kubectl create -f $USER_NAME-role-binding.yaml

CA_DATA="$(kubectl config view --flatten --minify |grep certificate-authority-data |awk '{print $2}')"
CONTEXT_NAME="$(kubectl config current-context)"
CLUSTER_NAME="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"${CONTEXT_NAME}\")].context.cluster}")"
SERVER_NAME="$(kubectl config view -o "jsonpath={.clusters[?(@.name==\"${CLUSTER_NAME}\")].cluster.server}")"

echo "---
apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: $CA_DATA
    server: $SERVER_NAME
  name: $CLUSTER_NAME

contexts:
- context:
    cluster: $CLUSTER_NAME
    NAME_SPACE: $NAME_SPACE
    user: $USER_NAME

users:
- name: $USER_NAME
  user:
    client-certificate-data: $USER_CERT
    client-key-data: $USER_KEY
---"> kubeconfig-$USER_NAME

echo "$USER_NAME's kubeconfig was created into `pwd`/kubeconfig-$USER_NAME"
echo "If you want to test execute this command \`KUBECONFIG=`pwd`/kubeconfig-$USER_NAME kubectl get po\`"

echo "Please share `pwd`/kubeconfig-$USER_NAME with $USER_NAME ."
