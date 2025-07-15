#!/bin/bash

secretName="capmox-manager-credentials"
envFile="secrets/capmox.env"
labels="cluster.x-k8s.io/provider=infrastructure-proxmox clusterctl.cluster.x-k8s.io= platform.ionos.com/secret-type=proxmox-credentials"
sealedSecretFile="overlays/mgmt/sealed-secrets.yaml"
namespace="cluster-api"

certFile="secrets/sealed-secrets.crt"
tempDir="./.temp"
secretFile="$tempDir/secret.yaml"
labeledSecretFile="$tempDir/labeled-secret.yaml"

mkdir -p $tempDir

kubectl create secret generic $secretName \
  --from-env-file=$envFile \
  --dry-run=client \
  --output yaml > $secretFile

kubectl label -f $secretFile $labels \
  --local \
  -o yaml > $labeledSecretFile

kubeseal \
  --cert $certFile \
  --secret-file $labeledSecretFile \
  --sealed-secret-file $sealedSecretFile \
  --namespace $namespace \
  --scope namespace-wide

rm -rf $tempDir