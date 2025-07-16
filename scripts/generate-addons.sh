#!/bin/bash

metricsServerVersion="v0.8.0"
externalSecretsVersion="v0.18.2"
certManagerVersion="v1.18.2"

tempDir="./.temp"

function generateBitwardenAddon() {

  secretName="bitwarden-access-token"
  envFile="secrets/bitwarden.env"
  addonFile="base/bitwarden-addon.yaml"
  workloadNamespace="external-secrets"

  certFile="secrets/sealed-secrets.crt"
  
  workloadNamespaceFile="$tempDir/namespace.yaml"
  secretFile="$tempDir/secret.yaml"
  crsFile="$tempDir/crs.yaml"

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

}

function generateMetricsServerAddon() {
  addonFile="base/metrics-server-addon.yaml"

  wget -O $tempDir/metrics-server.yaml https://github.com/kubernetes-sigs/metrics-server/releases/download/$metricsServerVersion/components.yaml

  kubectl create cm metrics-server \
    --from-file=$tempDir/metrics-server.yaml \
    --dry-run=client \
    -oyaml > $addonFile

  echo "---
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: metrics-server-addon
spec:
  clusterSelector:
    matchLabels:
      metricsServerAddon: enabled
  resources:
  - kind: ConfigMap
    name: metrics-server
  strategy: Reconcile" >> $addonFile

}

function generateExternalSecretsCRDsAddon() {
  addonFile="base/external-secrets-crds-addon.yaml"

  wget -O $tempDir/external-secrets-crds.yaml https://raw.githubusercontent.com/external-secrets/external-secrets/$externalSecretsVersion/deploy/crds/bundle.yaml

  kubectl create cm external-secrets-crds \
    --from-file=$tempDir/external-secrets-crds.yaml \
    --dry-run=client \
    -oyaml > $addonFile

  echo "---
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: external-secrets-crds-addon
spec:
  clusterSelector:
    matchLabels:
      externalSecretsCRDsAddon: enabled
  resources:
  - kind: ConfigMap
    name: external-secrets-crds
  strategy: ApplyOnce" >> $addonFile

}

function generateCertManagerCRDsAddon() {
  addonFile="base/cert-manager-crds-addon.yaml"

  wget -O $tempDir/cert-manager-crds.yaml https://github.com/cert-manager/cert-manager/releases/download/$certManagerVersion/cert-manager.crds.yaml

  kubectl create cm cert-manager-crds \
    --from-file=$tempDir/cert-manager-crds.yaml \
    --dry-run=client \
    -oyaml > $addonFile

  echo "---
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: cert-manager-crds-addon
spec:
  clusterSelector:
    matchLabels:
      certManagerCRDsAddon: enabled
  resources:
  - kind: ConfigMap
    name: cert-manager-crds
  strategy: ApplyOnce" >> $addonFile

}


function main() {

    mkdir -p $tempDir

    generateBitwardenAddon

    generateMetricsServerAddon

    generateExternalSecretsCRDsAddon

    generateCertManagerCRDsAddon

    rm -rf $tempDir

}

main