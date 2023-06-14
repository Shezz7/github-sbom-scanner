#!/bin/bash

PAGE_SIZE=100
PAGE_NUMBER=1
ORG="<ORG_NAME>"
# see this to get an idea of how a dependency should be formatted https://docs.github.com/en/rest/dependency-graph/sboms?apiVersion=2022-11-28#export-a-software-bill-of-materials-sbom-for-a-repository
# replace the sample dependency below with the one you want to scan for
DEPENDENCY="go:cloud.google.com/go/compute"

REPO_LIST=()

# check if GitHub token env variable is set
if [ -z ${GITHUB_TOKEN+x} ]; then
    echo "Set GITHUB_TOKEN with your GitHub token"
    exit 1
fi

while true
do
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG/repos?per_page=$PAGE_SIZE&page=$PAGE_NUMBER")

    REPO_NAMES=$(echo "$RESPONSE" | jq -r ".[] | select(.archived==false) | .name")

    if [ "$REPO_NAMES" == "" ]; then
        break
    fi

    REPO_LIST+=("$REPO_NAMES")
    ((PAGE_NUMBER++))
done

# search SBOM for dependency version
for repo in ${REPO_LIST[@]}
do
    echo -n "$repo,";
    SBOM=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$ORG/$repo/dependency-graph/sbom")
    VERSION=$(echo "$SBOM" | jq -r ".sbom.packages[] | select(.name==\"$DEPENDENCY\") | .versionInfo")
    if [ "$VERSION" != "" ]; then
        echo "$VERSION"
    else
        echo "NOT_FOUND"
    fi
done
