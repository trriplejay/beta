#!/bin/bash -e

export ORG='shippable'
export TEAM_ID=''
export TEAM_NAME='pushPull'
export GITHUB_API_URL='https://api.github.com'

export RES_PARAMS="team_params"
export RES_PARAMS_UP=$(echo $RES_PARAMS | awk '{print toupper($0)}')
export RES_PARAMS_STR=$RES_PARAMS_UP"_PARAMS"
export OWNER_TOKEN=$(eval echo "$"$RES_PARAMS_STR"_TOKEN")

set_context() {
  echo "ORG=$ORG"
  echo "TEAM_NAME=$TEAM_NAME"
  echo "GITHUB_API_URL=$GITHUB_API_URL"
  echo "RES_PARAMS_UP=$RES_PARAMS_UP"
  echo "RES_PARAMS_STR=$RES_PARAMS_STR"
  echo "OWNER_TOKEN=$OWNER_TOKEN"
}

check_jq() {
  {
    type jq &> /dev/null && echo "jq is already installed"
  } || {
    echo "Installing 'jq'"
    echo "----------------------------------------------"
    apt-get install -y jq
  }
}

get_team_id() {
  echo "Getting team id for $TEAM_NAME"
  echo "----------------------------------------------"
  local url="$GITHUB_API_URL/orgs/$ORG/teams"
  local teams=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNER_TOKEN" $url)
  TEAMID=$(echo $teams |  jq ".[] | select(.name==\"$TEAM_NAME\") | .id")
}

get_team_repos() {
  if [ $TEAMID != "" ] || [ $TEAMID != null ]; then
    echo "Getting team repositories for $TEAM_NAME"
    echo "----------------------------------------------"

    local url="$GITHUB_API_URL/teams/$TEAMID/repos"
    local res=$(curl --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNER_TOKEN" $url)
    if [ $? -eq 0 ]; then
      TEAM_REPOS=$(echo $res |  jq ".[] | .name")
    fi
  fi
}

change_permissions() {
  if [ -n "$TEAM_REPOS" ]; then
    echo "Changing permissions for $TEAM_NAME"
    echo "----------------------------------------------"

    local permission="$1"
    local data="{\"permission\": \"$permission\"}"
    for repo in $TEAM_REPOS; do
      #jq returned array of name has "" around the names hence escaping them here
      repo_name=$(echo "$repo" | sed -e 's/^"//' -e 's/"$//')
      url="$GITHUB_API_URL/teams/$TEAMID/repos/$ORG/$repo_name"

      #check if this repo is managed by the team
      local responseCode=$(curl --write-out %{http_code} --silent -X GET -H "Accept: application/json" -H "Authorization: token $OWNER_TOKEN" $url)
      if [ $responseCode -eq 204 ]; then
        local res=$(curl --write-out %{http_code} --silent -X PUT -H "Content-Type: application/json" -H "Accept: application/vnd.github.v3.repository+json" -H "Authorization: token $OWNER_TOKEN" $url -d "$data")
        if [ $res -eq 204 ]; then
          echo "Permission updated to $permission for $repo_name"
          echo "----------------------------------------------"
        else
          echo "Update $permission permission failed for $repo_name"
          echo "----------------------------------------------"
        fi
      fi
    done
  fi
}

main() {
  set_context
  check_jq
  get_team_id
  get_team_repos
  change_permissions "$@"
}

main "$@"
