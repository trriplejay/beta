#!/bin/bash -e

export RES_INFRA="infra-prov"
export RC_INTEGRATION=aws-rc-pem
export RC_SWARM=aws-rc-swarm

export RES_INFRA_UP=$(echo ${RES_INFRA//-/} | awk '{print toupper($0)}')
export RES_INFRA_STATE=$(eval echo "$"$RES_INFRA_UP"_STATE") #loc of git repo clone

test_env_info() {
  echo "########### RES_INFRA_STATE: $RES_INFRA_STATE"
  echo "successfully loaded node information"

  ls -al $RES_INFRA_STATE
}

save_version() {
  echo "Copying State file"
  echo "--------------------------------------"

  mkdir -p /build/state/alpha-saas
  mkdir -p /build/state/alpha-server
  mkdir -p /build/state/rc-saas
  mkdir -p /build/state/rc-server
  mkdir -p /build/state/prod-saas

  cp -vr "$RES_INFRA_STATE/alpha-saas/terraform.tfstate" "/build/state/alpha-saas/terraform.tfstate"
  cp -vr "$RES_INFRA_STATE/alpha-server/terraform.tfstate" "/build/state/alpha-server/terraform.tfstate"
  cp -vr "$RES_INFRA_STATE/rc-saas/terraform.tfstate" "/build/state/rc-saas/terraform.tfstate"
  cp -vr "$RES_INFRA_STATE/rc-server/terraform.tfstate" "/build/state/rc-server/terraform.tfstate"
  cp -vr "$RES_INFRA_STATE/prod-saas/terraform.tfstate" "/build/state/prod-saas/terraform.tfstate"

  ls -al /build/state/alpha-saas
  ls -al /build/state/alpha-server
  ls -al /build/state/rc-saas
  ls -al /build/state/rc-server
  ls -al /build/state/prod-saas

  echo "Copied all state files"
  echo "--------------------------------------"
}

main() {
  test_env_info
  save_version
}

main
