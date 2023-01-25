#! /usr/bin/env bash

set -eo pipefail

usage(){
  echo "ghes2ghes [repolist.csv] [https://ghes.domain.com/] [https://ghes2.domain.com/]
  \$1: the file to read which repo's to sync from one GHES instance to another.
  this script assumes some environment values are present and should be supplied before hand.
  SOURCE_TOKEN, DESTINATION_TOKEN.
  \$2: the prefix of the source GHES instance.
  \$3: the prefix of the destination GHES instance.
  "
}

if [ -e .env ]; then
  source .env
fi

if [ -z "${SOURCE_TOKEN}" ]; then
  echo "Please provide 'SOURCE_TOKEN', 'DESTINATION_TOKEN' environment variables."
  exit 1
fi

# per line: source_repo_https_uri;destination_repo_http_uri
repolist=${1:-repolist.csv}
source_prefix=${2:-'https://ghes.domain.com'}
destination_prefix=${3:-'https://ghes2.domain.com'}

if [ ! -e ${repolist} ]; then
  echo  "${repolist} not found"
  exit 1
fi

while read -r line
do
  # Split line on ';' and put in $linearr
  IFS=';' read -ra linearr <<< "$line"
  SOURCE_REPO=${linearr[0]}
  DESTINATION_REPO=${linearr[1]}

  echo "### Syncing prd ${SOURCE_REPO} to acc ${DESTINATION_REPO}"

  SOURCE_LOCATION="$(echo ${source_prefix}/${linearr[0]} | sed "s/\/\//\/\/app:${SOURCE_TOKEN}@/g").git"
  DESTINATION_LOCATION="$(echo ${destination_prefix}/${linearr[1]} | sed "s/\/\//\/\/app:${DESTINATION_TOKEN}@/g").git"

  git clone $SOURCE_LOCATION clone
  cd clone
  git remote add destination $DESTINATION_LOCATION
  # Force push, as we're overwriting everything
  git push -u destination --force

  cd ..
  rm -rf clone
  echo "${SOURCE_REPO} sync finished"
done < "${repolist}"
