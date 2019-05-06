# script to send an create Dynatrace deployment API call 
# define variables and call this script with
# these arguments
# "$(dynatrace-base-url)" "$(dynatrace-api-token)" Staging "$(Release.DefinitionName)" "$(app-problem-number)" $(System.TeamProject) $(Release.ReleaseWebURL)

DYNATRACE_BASE_URL="$1"
DYNATRACE_API_TOKEN="$2"
DEMO_APP_ENVIONMENT_TAG="$3"
AZ_RELEASE_DEFINITION_NAME="$4"
AZ_RELEASE_ID="$5"
AZ_RELEASE_TEAM_PROJECT="$6"
AZ_RELEASE_URL="$7"

DYNATRACE_API_URL="$1/api/v1/events"

echo "================================================================="
echo "Dynatrace Deployment event:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "DEMO_APP_ENVIONMENT_TAG    = $DEMO_APP_ENVIONMENT_TAG"
echo "AZ_RELEASE_DEFINITION_NAME = $AZ_RELEASE_DEFINITION_NAME"
echo "AZ_RELEASE_ID              = $AZ_RELEASE_ID"
echo "AZ_RELEASE_TEAM_PROJECT    = $AZ_RELEASE_TEAM_PROJECT"
echo "AZ_RELEASE_URL             = $AZ_RELEASE_URL"
echo "================================================================="
POST_DATA=$(cat <<EOF
    {
        "eventType" : "CUSTOM_DEPLOYMENT",
        "source" : "AzureDevops" ,
        "deploymentName" : "$AZ_RELEASE_DEFINITION_NAME",
        "deploymentVersion" : "$AZ_RELEASE_ID"  ,
        "deploymentProject" : "$AZ_RELEASE_TEAM_PROJECT" ,
        "ciBackLink" : "$AZ_RELEASE_URL",
        "attachRules" : {
               "tagRule" : [
                   {
                        "meTypes":"SERVICE" ,
                        "tags" : [
                            {
                                "context" : "CONTEXTLESS",
                                "key": "environment",
                                "value" : "$DEMO_APP_ENVIONMENT_TAG"    
                            }
                            ]
                   }
                   ]
        }
    }
EOF)

curl --url "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -X POST -d "$POST_DATA"