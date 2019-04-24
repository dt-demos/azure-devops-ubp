# user defined values
USER_NAME="$1"
RESOURCE_GROUP_LOCATION="$2"
ARM_LOCATION="$3"
PITOMETER_IMAGE="$4"
SUBSCRIPTION_ID="$5"
DYNATRACE_ENVIONMENT_ID="$6"
DYNATRACE_PAAS_TOKEN="$7"
DYNATRACE_API_TOKEN="$8"
DYNATRACE_BASE_URL="$9"

# auto-generated values
RESOURCE_GROUP_NAME=$USER_NAME-ubp-demo-rg
APP_SERVICE_PLAN_NAME=$USER_NAME-ubp-demo-plan
PITOMETER_APP_NAME=$USER_NAME-ubp-demo-pitometer
DEMO_APP_STAGING_NAME=$USER_NAME-ubp-demo-app-staging
DEMO_APP_PRODUCTION_NAME=$USER_NAME-ubp-demo-app-production
DYNATRACE_API_URL=$DYNATRACE_BASE_URL/e/$DYNATRACE_ENVIONMENT_ID/api

TEMPLATE_FILE_PATH="$(Build.SourcesDirectory)/arm/webapp-template.json"

echo "================================================================="
echo "Provisioning with:"
echo ""
echo "USER_NAME                = $USER_NAME"
echo "RESOURCE_GROUP_LOCATION  = $RESOURCE_GROUP_LOCATION"
echo "ARM_LOCATION             = $ARM_LOCATION"
echo "PITOMETER_IMAGE          = $PITOMETER_IMAGE"
echo "SUBSCRIPTION_ID          = $SUBSCRIPTION_ID"
echo "DYNATRACE_ENVIONMENT_ID  = $DYNATRACE_ENVIONMENT_ID"
echo "DYNATRACE_BASE_URL       = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL        = $DYNATRACE_API_URL"
echo "RESOURCE_GROUP_NAME      = $RESOURCE_GROUP_NAME"
echo "APP_SERVICE_PLAN_NAME    = $APP_SERVICE_PLAN_NAME"
echo "PITOMETER_APP_NAME       = $PITOMETER_APP_NAME"
echo "DEMO_APP_STAGING_NAME    = $DEMO_APP_STAGING_NAME"
echo "DEMO_APP_PRODUCTION_NAME = $DEMO_APP_PRODUCTION_NAME"
echo "TEMPLATE_FILE_PATH       = $TEMPLATE_FILE_PATH"
echo "================================================================="
ls -l $TEMPLATE_FILE_PATH
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
  --environment-variables 'DYNATRACE_BASEURL'='$DYNATRACE_BASE_URL' 'DYNATRACE_APITOKEN'='$DYNATRACE_API_TOKEN'

echo "================================================================="
echo "Create Staging webapp"
echo "================================================================="

echo "Starting deployment for $DEMO_APP_STAGING_NAME"
(
    set -x
    az group deployment create --name "$DEMO_APP_STAGING_NAME-dg" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "$TEMPLATE_FILE_PATH" \
    --parameters "name=$DEMO_APP_STAGING_NAME" \
    --parameters "hostingPlanName=$APP_SERVICE_PLAN_NAME" \
    --parameters "hostingEnvironment=" \
    --parameters "location=$ARM_LOCATION" \
    --parameters "serverFarmResourceGroup=$RESOURCE_GROUP_NAME" \
    --parameters "subscriptionId=$SUBSCRIPTION_ID" \
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
    --template-file "$TEMPLATE_FILE_PATH" \
    --parameters "name=$DEMO_APP_PRODUCTION_NAME" \
    --parameters "hostingPlanName=$APP_SERVICE_PLAN_NAME" \
    --parameters "hostingEnvironment=" \
    --parameters "location=$ARM_LOCATION" \
    --parameters "serverFarmResourceGroup=$RESOURCE_GROUP_NAME" \
    --parameters "subscriptionId=$SUBSCRIPTION_ID" \
    --parameters "dynatrace-environment-id=$DYNATRACE_ENVIONMENT_ID" \
    --parameters "dynatrace-paas-token=$DYNATRACE_PAAS_TOKEN" \
    --parameters "dynatrace-api-url=$DYNATRACE_API_URL" \
    --parameters "website-node-default-version=10.14.1"
)

if [ $? == 0 ]; then
  echo "$DEMO_APP_PRODUCTION_NAME has been successfully deployed"
fi