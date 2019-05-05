# script to remove provision demo azure infrastrucure
# define variables and call this script with
# these arguments
# "$(username)" 

# user defined values
USER_NAME="$1"

# auto-generated values
RESOURCE_GROUP_NAME=$USER_NAME-ubp-demo-rg

echo "================================================================="
echo "Check for existing RG"
echo "================================================================="
az group show --name "$RESOURCE_GROUP_NAME"

if [ $? != 0 ]; then
  echo "Resource group with name $RESOURCE_GROUP_NAME could not be found."
else
  set -e
  echo "Deleting resource group $RESOURCE_GROUP_NAME"
  az group delete --name "$RESOURCE_GROUP_NAME" --yes
fi