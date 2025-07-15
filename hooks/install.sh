#!/bin/bash

repoDir=$(pwd)

mkdir -p $repoDir/.git/hooks/
for hook in $(ls hooks | grep -v install.sh); do
  if [ ! -e "$repoDir/.git/hooks/$hook" ]; then
    chmod +x hooks/$hook
    ln -s $repoDir/hooks/$hook $repoDir/.git/hooks/$hook
  fi
done