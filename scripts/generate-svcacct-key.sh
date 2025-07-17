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

secretName="service-account-signing-key"
sealedSecretPath="overlays/$clusterName/$secretName.yaml"
serviceAccountSigningKeyFile="secrets/$clusterName-sa.key"
serviceAccountKeyFile="secrets/$clusterName-sa.pub"

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
  --from-file=sa.key=$serviceAccountSigningKeyFile \
  --from-file=sa.pub=$serviceAccountKeyFile \
  --dry-run=client -oyaml > $tempDir/unsealed-secret.yaml

echo "Sealing $secretName secret..."

kubeseal \
  --scope namespace-wide \
  --namespace $clusterName \
  --secret-file $tempDir/unsealed-secret.yaml \
  --cert $certFile \
  --format yaml > $sealedSecretPath

rm -rf $tempDir
