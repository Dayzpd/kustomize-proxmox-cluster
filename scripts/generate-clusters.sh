#!/bin/bash

currentDir=$( pwd )
clusterName="prodlab"

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

clusterctlConfig="clusterctl-$clusterName.yaml"
clusterDir="overlays/$clusterName"

if [ ! -f "$clusterctlConfig" ]; then
  echo "Could not find clusterctl config file '$clusterctlConfig'"
  exit 1
fi

mkdir -p $clusterDir

kubectl create ns $clusterName \
  --dry-run=client \
  -oyaml > $clusterDir/namespace.yaml

clusterctl generate yaml \
  --config $clusterctlConfig \
  --from templates/proxmox-cluster-template.yaml > $clusterDir/proxmox-cluster.yaml

cd $clusterDir

rm -f kustomization.yaml

kustomize create \
  --namespace $clusterName \
  --resources ../../base,namespace.yaml,proxmox-cluster.yaml

cd $currentDir
