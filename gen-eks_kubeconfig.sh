#!/bin/bash

###
# Creating or updating a kubeconfig file manually for an Amazon EKS cluster.
#
# Prerequisites:
# - Version 2.11.3 or later or 1.27.93 or later of the AWS CLI installed and configured on your device.
# - Existing Amazon EKS cluster
#
# Credits:- https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
###

read -p "Enter AWS Reagion Code: " region_code
read -p "Enter AWS Account ID: " account_id
read -p "Enter Amazon EKS Cluster Name: " cluster_name
echo "The KUBECONFIG file will be named 'kube_config-$cluster_name'."
read -p "Enter absolute path to save the kubeconfig file: " path_config


cluster_endpoint=$(aws eks describe-cluster \
    --region $region_code \
    --name $cluster_name \
    --query "cluster.endpoint" \
    --output text)

certificate_data=$(aws eks describe-cluster \
    --region $region_code \
    --name $cluster_name \
    --query "cluster.certificateAuthority.data" \
    --output text)

read -r -d '' KUBECONFIG <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $certificate_data
    server: $cluster_endpoint
  name: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
contexts:
- context:
    cluster: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
    user: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
  name: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
current-context: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
kind: Config
preferences: {}
users:
- name: arn:aws:eks:$region_code:$account_id:cluster/$cluster_name
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - --region
        - $region_code
        - eks
        - get-token
        - --cluster-name
        - $cluster_name
        # - "- --role"
        # - "arn:aws:iam::$account_id:role/my-role"
      # env:
        # - name: "AWS_PROFILE"
        #   value: "aws-profile"
EOF

echo "${KUBECONFIG}" > $path_config/kube_config-$cluster_name
