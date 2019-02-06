#!/bin/bash

# Access granted under MIT Open Source License: https://en.wikipedia.org/wiki/MIT_License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, # and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions 
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE.


set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

env_name="${1-}"
rg_name="${2-}"
rg_location="${3-}"
sub_id="${4-}"

#####################
# Deploy ARM template

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $sub_id"
az account set --subscription $sub_id

# Retrieve KeyVault User Id
upn=$(az account show --output json | jq -r '.user.name')
kvOwnerObjectId=$(az ad user show --upn $upn \
    --output json | jq -r '.objectId')

# Create resource group
echo "Creating resource group: $rg_name"
az group create --name "$rg_name" --location "$rg_location"

# Deploy arm template
echo "Deploying resources into $rg_name"
arm_output=$(az group deployment create \
    --name "$deploy_name" \
    --resource-group "$rg_name" \
    --template-file "./azuredeploy.json" \
    --parameters @"./azuredeploy.parameters.${env_name}.json" \
    --parameters "kvOwnerObjectId=${kvOwnerObjectId}" \
    --output json)

if [[ -z $arm_output ]]; then
    echo >&2 "ARM deployment failed." 
    exit 1
fi