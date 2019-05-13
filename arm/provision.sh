# script to provision demo azure infrastrucure
# define variables and call this script with
# these arguments
# "$(azure-resource-prefix)" "$(location)" "$(location-code)" "$(pitometer-image)" "$(azure-subscription-name)" "$(dynatrace-environment-id)" "$(dynatrace-paas-token)" "$(dynatrace-api-token)" "$(dynatrace-base-url)" $(Build.SourcesDirectory)

# user defined values
AZURE_RESOURCE_PREFIX="$1"
RESOURCE_GROUP_LOCATION="$2"
ARM_LOCATION="$3"
PITOMETER_IMAGE="$4"
AZURE_SUBSCRIPTION_NAME="$5"
DYNATRACE_ENVIONMENT_ID="$6"
DYNATRACE_PAAS_TOKEN="$7"
DYNATRACE_API_TOKEN="$8"
DYNATRACE_BASE_URL="$9"
BUILD_SOURCE_DIR="${10}"

# auto-generated values
RESOURCE_GROUP_NAME=$AZURE_RESOURCE_PREFIX-ubp-demo-rg
APP_SERVICE_PLAN_NAME=$AZURE_RESOURCE_PREFIX-ubp-demo-plan
PITOMETER_APP_NAME=$AZURE_RESOURCE_PREFIX-ubp-demo-pitometer
DEMO_APP_STAGING_NAME=$AZURE_RESOURCE_PREFIX-ubp-demo-app-staging
DEMO_APP_PRODUCTION_NAME=$AZURE_RESOURCE_PREFIX-ubp-demo-app-production
LOGIC_APP_NAME=$AZURE_RESOURCE_PREFIX-ubp-demo-logic-app-self-healing
DYNATRACE_API_URL=$DYNATRACE_BASE_URL/e/$DYNATRACE_ENVIONMENT_ID/api
DEMO_APP_TEMPLATE_FILE_PATH=$BUILD_SOURCE_DIR/arm/webapp-template.json
LOGIC_APP_TEMPLATE_FILE_PATH=$BUILD_SOURCE_DIR/arm/logicapp-template.json

echo "================================================================="
echo "Provisioning with:"
echo ""
echo "AZURE_SUBSCRIPTION_NAME      = $AZURE_SUBSCRIPTION_NAME"
echo "ARM_LOCATION                 = $ARM_LOCATION"
echo "RESOURCE_GROUP_LOCATION      = $RESOURCE_GROUP_LOCATION"
echo "RESOURCE_GROUP_NAME          = $RESOURCE_GROUP_NAME"
echo "AZURE_RESOURCE_PREFIX        = $AZURE_RESOURCE_PREFIX"
echo "-----------------------------"
echo "DYNATRACE_ENVIONMENT_ID      = $DYNATRACE_ENVIONMENT_ID"
echo "DYNATRACE_BASE_URL           = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL            = $DYNATRACE_API_URL"
echo "-----------------------------"
echo "PITOMETER_APP_NAME           = $PITOMETER_APP_NAME"
echo "PITOMETER_IMAGE              = $PITOMETER_IMAGE"
echo "-----------------------------"
echo "APP_SERVICE_PLAN_NAME        = $APP_SERVICE_PLAN_NAME"
echo "DEMO_APP_TEMPLATE_FILE_PATH  = $DEMO_APP_TEMPLATE_FILE_PATH"
echo "DEMO_APP_STAGING_NAME        = $DEMO_APP_STAGING_NAME"
echo "DEMO_APP_PRODUCTION_NAME     = $DEMO_APP_PRODUCTION_NAME"
echo "-----------------------------"
echo "LOGIC_APP_NAME               = $LOGIC_APP_NAME"
echo "LOGIC_APP_TEMPLATE_FILE_PATH = $LOGIC_APP_TEMPLATE_FILE_PATH"
echo "================================================================="
echo "Pipeline source files within $BUILD_SOURCE_DIR"
ls -l $BUILD_SOURCE_DIR
echo "================================================================="

echo "================================================================="
echo "Check for existing RG"
echo "================================================================="
az group show --name "$RESOURCE_GROUP_NAME"

if [ $? != 0 ]; then
  echo "Resource group with name $RESOURCE_GROUP_NAME could not be found."
  set -e
  (
    set -x
    echo "Creating resource group $RESOURCE_GROUP_NAME in $RESOURCE_GROUP_LOCATION"
    az group create --name "$RESOURCE_GROUP_NAME" --location "$RESOURCE_GROUP_LOCATION"
  )
  else
    echo "Using existing resource group $RESOURCE_GROUP_NAME in $RESOURCE_GROUP_LOCATION"
fi

echo "================================================================="
echo "Check for existing App Service plan"
echo "================================================================="
appPlanCount=`az appservice plan show --name "$APP_SERVICE_PLAN_NAME" --resource-group $RESOURCE_GROUP_NAME | wc -l`
echo "appPlanCount: $appPlanCount"

if [ $appPlanCount -eq "0" ]; then
  echo "App Service with name $APP_SERVICE_PLAN_NAME could not be found."
  set -e
  (
    set -x
    echo "Creating App Service $APP_SERVICE_PLAN_NAME in $RESOURCE_GROUP_NAME resource group"
    # Create an App Service plan in `FREE` tier.
    az appservice plan create --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP_NAME" --sku FREE
  )
  else
    echo "Using existing App Service $APP_SERVICE_PLAN_NAME in $RESOURCE_GROUP_NAME resource group"
fi

echo "================================================================="
echo "Create Pitometer service"
echo "================================================================="

az container create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$PITOMETER_APP_NAME" \
  --image "$PITOMETER_IMAGE" \
  --restart-policy OnFailure \
  --ip-address public \
  --ports 8080 \
  --environment-variables 'DYNATRACE_BASEURL'=$DYNATRACE_BASE_URL 'DYNATRACE_APITOKEN'=$DYNATRACE_API_TOKEN

echo "================================================================="
echo "Create Staging webapp"
echo "================================================================="

echo "Starting deployment for $DEMO_APP_STAGING_NAME"
(
    set -x
    az group deployment create --name "$DEMO_APP_STAGING_NAME-dg" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$DEMO_APP_TEMPLATE_FILE_PATH" \
    --parameters "name=$DEMO_APP_STAGING_NAME" \
    --parameters "hostingPlanName=$APP_SERVICE_PLAN_NAME" \
    --parameters "hostingEnvironment=" \
    --parameters "location=$ARM_LOCATION" \
    --parameters "serverFarmResourceGroup=$RESOURCE_GROUP_NAME" \
    --parameters "subscriptionId=$AZURE_SUBSCRIPTION_NAME" \
    --parameters "dynatrace-environment-id=$DYNATRACE_ENVIONMENT_ID" \
    --parameters "dynatrace-paas-token=$DYNATRACE_PAAS_TOKEN" \
    --parameters "dynatrace-api-url=$DYNATRACE_API_URL" \
    --parameters "website-node-default-version=10.14.1"
)

if [ $? == 0 ]; then
  echo "$DEMO_APP_STAGING_NAME has been successfully deployed"
fi

echo "================================================================="
echo "Create Production webapp"
echo "================================================================="

echo "Starting deployment for $DEMO_APP_PRODUCTION_NAME"
(
    set -x
    az group deployment create --name "$DEMO_APP_PRODUCTION_NAME-dg" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$DEMO_APP_TEMPLATE_FILE_PATH" \
    --parameters "name=$DEMO_APP_PRODUCTION_NAME" \
    --parameters "hostingPlanName=$APP_SERVICE_PLAN_NAME" \
    --parameters "hostingEnvironment=" \
    --parameters "location=$ARM_LOCATION" \
    --parameters "serverFarmResourceGroup=$RESOURCE_GROUP_NAME" \
    --parameters "subscriptionId=$AZURE_SUBSCRIPTION_NAME" \
    --parameters "dynatrace-environment-id=$DYNATRACE_ENVIONMENT_ID" \
    --parameters "dynatrace-paas-token=$DYNATRACE_PAAS_TOKEN" \
    --parameters "dynatrace-api-url=$DYNATRACE_API_URL" \
    --parameters "website-node-default-version=10.14.1"
)

if [ $? == 0 ]; then
  echo "$DEMO_APP_PRODUCTION_NAME has been successfully deployed"
fi

echo "================================================================="
echo "Starting deployment for $LOGIC_APP_NAME"
echo "================================================================="
(
    set -x
    az group deployment create --name "$LOGIC_APP_NAME-dg" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$LOGIC_APP_TEMPLATE_FILE_PATH" \
    --parameters "logicAppName=$LOGIC_APP_NAME"

    # future idea
    #--parameters "dynatrace-api-token=$DYNATRACE_API_TOKEN" \
    #--parameters "dynatrace-base-url=$DYNATRACE_BASE_URL"
)
