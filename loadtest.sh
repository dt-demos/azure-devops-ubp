#!/bin/bash

APP_ENVIRONMENT=$1
APP_URL=$2
DURATION_SECONDS=$3

if [ -z "$1" ] ; then
  echo "Missing APP_ENVIRONMENT argument"
  exit 1
fi

if [ -z "$2" ] ; then
  echo "Missing APP_URL argument"
  exit 1
fi

# this is safe-guard to prevent infinit loop
if [ -z "$3" ] ; then
  DURATION_SECONDS=15
fi

echo "======================================"
echo "Load Test Launched in:"
echo "APP_ENVIRONMENT = $APP_ENVIRONMENT"
echo "APP_URL = $APP_URL"
echo "DURATION_SECONDS = $DURATION_SECONDS"
echo "======================================"

end=$(( SECONDS+$DURATION_SECONDS ))
while [ $SECONDS -lt $end ]; do
  # In Production we sleep less which means we will have more load
  # In Non-Production we also add the x-dynatrace HTTP Header so that we can 
  # demo Dynatrace "load testing integration" options using Request Attributes!
  if [[ $APP_ENVIRONMENT == *"Production"* ]]; then
    echo "Calling production @ $SECONDS seconds into test"
    curl "$APP_URL" --silent --output /dev/null
    curl "$APP_URL/version" --silent --output /dev/null
    curl "$APP_URL/api/echo?text=This%20is%20from%20a%20production%20user" --silent --output /dev/null
    curl "$APP_URL/api/invoke?url=http://www.dynatrace.com" --silent --output /dev/null
    curl "$APP_URL/api/invoke?url=http://blog.dynatrace.com" --silent --output /dev/null
    # less think time in production, thus will generate more load
    sleep 2;
  else
    echo "Calling non-production @ $SECONDS seconds into test"
    curl "$APP_URL" -H "x-dynatrace: NA=Test.Homepage;" --silent --output /dev/null
    curl "$APP_URL/version" -H "x-dynatrace: NA=Test.Version;" --silent --output /dev/null
    curl "$APP_URL/api/echo?text=This%20is%20from%20a%20nonproduction%20user" -H "x-dynatrace: NA=Test.Echo;" --silent --output /dev/null
    curl "$APP_URL/api/invoke?url=http://www.dynatrace.com" -H "x-dynatrace: NA=Test.Invoke;" --silent --output /dev/null
    sleep 5;
  fi
done;
exit 0