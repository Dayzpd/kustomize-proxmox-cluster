#!/bin/bash

secretName="bitwarden-access-token"
envFile="secrets/bitwarden.env"
addonFile="base/bitwarden-addon.yaml"
workloadNamespace="bitwarden"

certFile="secrets/sealed-secrets.crt"
tempDir="./.temp"
workloadNamespaceFile="$tempDir/namespace.yaml"
secretFile="$tempDir/secret.yaml"
crsFile="$tempDir/crs.yaml"

mkdir -p $tempDir

kubectl create ns $workloadNamespace \
  --dry-run=client \
  -oyaml > $workloadNamespaceFile

kubectl create cm $workloadNamespace-namespace \
  --from-file=$workloadNamespaceFile \
  --dry-run=client \
  -oyaml > $addonFile

kubectl create secret generic $secretName \
  --namespace $workloadNamespace \
  --from-env-file=$envFile \
  --dry-run=client \
  --output yaml > $secretFile

kubectl create secret generic $secretName \
  --from-file=$secretFile \
  --type=addons.cluster.x-k8s.io/resource-set \
  --dry-run=client -oyaml > $crsFile

kubeseal \
  --scope cluster-wide \
  --secret-file $crsFile \
  --cert $certFile \
  --format yaml >> $addonFile

echo "---
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: bitwarden-addon
spec:
  clusterSelector:
    matchLabels:
      bitwardenAddon: enabled
  resources:
  - kind: ConfigMap
    name: bitwarden-namespace
  - kind: Secret
    name: bitwarden-access-token
  strategy: Reconcile" >> $addonFile

rm -rf $tempDir