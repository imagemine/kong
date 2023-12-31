#!/usr/bin/env bash

set -eo pipefail

current_hash=$(git log --pretty=format:'%h' --max-count=1)
current_branch=$(git branch --show-current|sed 's#/#_#')

version=""
: "${push:=${1:-yes}}"

create_tag() {
    if [[ ${current_branch} == "main" ]]; 
    then
        git fetch --tags --force
        current_version_at_head=$(git tag --points-at HEAD)
        if [[ -z ${current_version_at_head} ]] || [[ ! "${current_version_at_head}" =~ ^b+ ]] || [[ "${push}" == "no" ]];
        then 
            commit_hash=$(git rev-list --tags --topo-order --max-count=1)
            latest_version=""
            if [[ "${commit_hash}" != "" ]]; then            
              latest_version=$(git describe --tags ${commit_hash} 2>/dev/null)
            fi;
            if [[ ${latest_version} =~ ^b+ ]];
            then 
                read a b c <<< $(echo $latest_version|sed 's/\./ /g')
                version="$a.$b.$((c+1))"
            else
                version="b1.0.0"
            fi;
	          echo "version: ${version}"
        else
            echo nothing to build
        fi;
    fi;
}

create_tag

if [[ ! -z ${version} ]];
then
  source project.properties
  image_version_tag="${owner}/${project}:${kong_version}-${version}"
  image_kong_version_tag="${owner}/${project}:${kong_version}"
  image_latest_tag="${owner}/${project}:latest"
  echo building ${image_version_tag}
  docker build --no-cache -t ${image_version_tag} --build-arg KONG_VERSION=${kong_version} .
  docker tag ${image_version_tag} ${image_latest_tag}
  docker tag ${image_version_tag} ${image_kong_version_tag}
  if [[ "${push}" == "yes" ]]; then 
    docker push ${image_version_tag}
    docker push ${image_latest_tag}
    docker push ${image_kong_version_tag}
  fi;

  now=$(date '+%Y-%m-%dT%H:%M:%S%z')

  git config --global user.email "${email}"
  git config --global user.name "${name}"
  if [[ "${push}" == "yes" ]]; then
    git tag -m "{\"author\":\"ci\", \"branch\":\"$current_branch\", \"hash\": \"${current_hash}\", \"version\":\"${version}\",  \"build_date\":\"${now}\"}"  ${version}
    git push --tags
  fi;
fi;
