#!/bin/bash

clusterName="prodlab"
tempDir="./.temp"
certFile="secrets/sealed-secrets.crt"

for arg in \"$@\"
  do
  case $1 in
    --cluster|-c)
      clusterName=$2
    ;;
    --*)
      echo "Unknown option: $1"
      exit 1
    ;;
  esac
  shift
done

secretName="$clusterName-sa"
secretLabels="cluster.x-k8s.io/cluster-name=$clusterName"
sealedSecretPath="overlays/$clusterName/$secretName.yaml"
serviceAccountSigningKeyFile="secrets/$secretName.key"
serviceAccountKeyFile="secrets/$secretName.pub"

mkdir -p $tempDir

if [ ! -e $serviceAccountSigningKeyFile ]; then
  
  echo "Generating Service Account Signing Key..."

  openssl genrsa -out $serviceAccountSigningKeyFile 4096

  openssl rsa -in $serviceAccountSigningKeyFile -pubout -out $serviceAccountKeyFile

else

  echo "Service Account Signing Key already exists."

fi

echo "Creating $secretName secret file..."

kubectl create secret generic $secretName \
  --namespace $clusterName \
  --type=cluster.x-k8s.io/secret \
  --from-file=tls.key=$serviceAccountSigningKeyFile \
  --from-file=tls.crt=$serviceAccountKeyFile \
  --dry-run=client -oyaml > $tempDir/unlabeled-secret.yaml

kubectl label -f $tempDir/unlabeled-secret.yaml $secretLabels \
  --local \
  -o yaml > $tempDir/labeled-secret.yaml


echo "Sealing $secretName secret..."

kubeseal \
  --scope namespace-wide \
  --namespace $clusterName \
  --secret-file $tempDir/labeled-secret.yaml \
  --cert $certFile \
  --format yaml > $sealedSecretPath

rm -rf $tempDir
