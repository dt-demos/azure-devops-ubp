echo "================================================================="
echo "Check for existing RG"
echo "================================================================="
az group show --name $(resource-group-name)

if [ $? != 0 ]; then
  echo "Resource group with name" $(resource-group-name) "could not be found. Creating new resource group.."
  set -e
  (
    set -x
    echo "Creating resource group $(resource-group-name) in $(location)"
    az group create --name $(resource-group-name) --location $(location)
  )
  else
    echo "Using existing resource group $(resource-group-name) in $(location)"
fi

echo "================================================================="
echo "Create Pitometer service"
echo "================================================================="

az container create \
  --resource-group "$(resource-group-name)" \
  --name "$(pitometer-webapp-name)" \
  --image "$(pitometer-image)" \
  --restart-policy OnFailure \
  --ip-address public \
  --ports 8080 \
  --environment-variables 'DYNATRACE_BASEURL'='$(dynatrace-base-url)' 'DYNATRACE_APITOKEN'='$(dynatrace-api-token)'

echo "================================================================="
echo "Create Staging webapp"
echo "================================================================="

templateFilePath="$(Build.SourcesDirectory)/arm/webapp-template.json"
echo "templateFilePath = $templateFilePath"
ls -l $templateFilePath

echo "Starting deployment for $(demo-webapp-name-staging)"
(
    set -x
    az group deployment create --name "$(demo-webapp-name-staging)-dg" \
    --resource-group "$(resource-group-name)" \
    --template-file "$templateFilePath" \
    --parameters "name=$(demo-webapp-name-staging)" \
    --parameters "hostingPlanName=$(hosting-plan-name)" \
    --parameters "hostingEnvironment=" \
    --parameters "location=$(location)" \
    --parameters "serverFarmResourceGroup=$(resource-group-name)" \
    --parameters "subscriptionId=$(subscription-id)" \
    --parameters "dynatrace-environment-id=$(dynatrace-environment-id)" \
    --parameters "dynatrace-paas-token=$(dynatrace-paas-token)" \
    --parameters "dynatrace-api-url=$(dynatrace-api-url)" \
    --parameters "website-node-default-version=10.14.1"
)

if [ $? == 0 ]; then
  echo "$(demo-webapp-name-staging) has been successfully deployed"
fi

echo "================================================================="
echo "Create Production webapp"
echo "================================================================="

echo "Starting deployment for $(demo-webapp-name-production)"
(
    set -x
    az group deployment create --name "$(demo-webapp-name-production)-dg" \
    --resource-group "$(resource-group-name)" \
    --template-file "$templateFilePath" \
    --parameters "name=$(demo-webapp-name-production)" \
    --parameters "hostingPlanName=$(hosting-plan-name)" \
    --parameters "hostingEnvironment=" \
    --parameters "location=$(location)" \
    --parameters "serverFarmResourceGroup=$(resource-group-name)" \
    --parameters "subscriptionId=$(subscription-id)" \
    --parameters "dynatrace-environment-id=$(dynatrace-environment-id)" \
    --parameters "dynatrace-paas-token=$(dynatrace-paas-token)" \
    --parameters "dynatrace-api-url=$(dynatrace-api-url)" \
    --parameters "website-node-default-version=10.14.1"
)

if [ $? == 0 ]; then
  echo "$(demo-webapp-name-production) has been successfully deployed"
fi