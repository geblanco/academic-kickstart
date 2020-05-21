#!/bin/bash

set -e

go_git(){
  git add --all
  git commit -m $@
  git push
}

read -p "Commit msg?: "  message
hugo
cd public
go_git "${message}"
cd -
go_git "${message}"

