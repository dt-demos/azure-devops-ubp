# Overview

This folder has scripts and azure resource temlates for provisioning a demo envionment.

When this is done you will have these resources within your defined resource group.

<img src="images/az-resourcegroup.png" width="500"/>

# Pitometer container app

Web service will be reachable @ ```http://<IP Address:8080/api/pitometer```

<img src="images/az-pitometer.png" width="500"/>

# Demo Web apps

Demo app will be reachable @ listed URL.

<img src="images/az-webapp.png" width="500"/>

# How to provision

There are two scripts to provision and remove the azure resources.  Both required you to first define the inputs.

1. Provision resources - creates a resource group and resources
    ```
    # user input values
    export RESOURCE_PREFIX="<name that will prefix all resources names. example your last name>
    export AZURE_LOCATION="<value like 'East US'>"
    export AZURE_LOCATION_CODE="<value like 'eastus'>"
    export PITOMETER_IMAGE="<if you did not build your own, use robjahn/pitometer-web-service>"
    export AZURE_SUBSCRIPTION_ID="<guid id for your azure subscription>"
    export DYNATRACE_ENVIONMENT_ID="<ID value like gan12345>"
    export DYNATRACE_PAAS_TOKEN="<PaaS Token value>"
    export DYNATRACE_API_TOKEN="<API Token value>"
    export DYNATRACE_BASE_URL="<example https://gan12345.live.dynatrace.com"
    export ARM_TEMPLATE_DIR="<location of arm template files.  Just use the value '.' if running locally>"

    # Provision resources
    ./provision.sh /
        "$RESOURCE_PREFIX" /
        "$AZURE_LOCATION" /
        "$AZURE_LOCATION_CODE" /
        "$PITOMETER_IMAGE" /
        "$AZURE_SUBSCRIPTION_ID" /
        "$DYNATRACE_ENVIONMENT_ID" /
        "$DYNATRACE_PAAS_TOKEN" /
        "$DYNATRACE_API_TOKEN" /
        "$DYNATRACE_BASE_URL" /
        "$ARM_TEMPLATE_DIR"
    ```

1. Remove resources -- this just deletes the azure resource group that contains all that your provisioned.
    ```
    export RESOURCE_PREFIX="<same value you used for provision.sh>"
    ./remove.sh $RESOURCE_PREFIX
    ```

# Pitometer service Testing

A tool like [postman](https://www.getpostman.com/) can be used to make the POST request to test our your PerfSpec file.

<img src="images/postman-header.png" width="500"/>
<img src="images/postman.png" width="500"/>