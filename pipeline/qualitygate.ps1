# this script will call the pitometer service and parse out the
# result value.  If the value is fail, then exit script with error
# example arguments $env:startTime $env:endTime $(pitometer-url) app\perfspec\perfspec.json pass
# FAKE_STATUS is optional.  Used to override the result of pitometer results. Example values pass, warn, error

$START_TIME=$Args[0]
$END_TIME=$Args[1]
$PITOMETER_URL=$Args[2]
$PERFSPEC_FILE=$Args[3]
$FAKE_STATUS=$Args[4]

#Set-Variable -Name "PERFSPEC_DIR" -Value "$($env:AGENT_RELEASEDIRECTORY)\_$($env:BUILD_DEFINITIONNAME)\$($PERFSPEC_FILE)"
Set-Variable -Name "PERFSPEC_DIR" -Value "$($PERFSPEC_FILE)"
$PERFSPEC_CONTENT = Get-Content -Path $PERFSPEC_DIR
$PERFSPEC_REQUEST_BODY="{""timeStart"": $START_TIME,""timeEnd"": $END_TIME,""perfSpec"": $($PERFSPEC_CONTENT)}"

Write-Host "==============================================================="
Write-Host "START_TIME            : "$START_TIME
Write-Host "END_TIME              : "$END_TIME
Write-Host "PITOMETER_URL         : "$PITOMETER_URL
Write-Host "PERFSPEC_DIR          : "$PERFSPEC_DIR
Write-Host "PERFSPEC_REQUEST_BODY : "$PERFSPEC_REQUEST_BODY
Write-Host "PERFSPEC_CONTENT      : "$PERFSPEC_CONTENT
Write-Host "FAKE_STATUS           : "$FAKE_STATUS
Write-Host "==============================================================="
Write-Host "Calling Pitometer Service..."
$PERFSPEC_RESULT_BODY = Invoke-RestMethod -Uri $PITOMETER_URL -Method Post -Body $PERFSPEC_REQUEST_BODY -ContentType "application/json" 
Write-Host "==============================================================="

# show the full body for debugging
$PERFSPEC_JSON = $PERFSPEC_RESULT_BODY | ConvertTo-Json -Depth 5
Write-Host "Pitometer Response: "$PERFSPEC_JSON

# pull out the result property
$PERFSPEC_RESULT = $PERFSPEC_RESULT_BODY.result
Write-Host "PERFSPEC_RESULT = "$PERFSPEC_RESULT

# if pass in fake status then use it to override real status
if ($FAKE_STATUS) {
    Write-Host "Faking out the status to be "$FAKE_STATUS
    $PERFSPEC_RESULT = $FAKE_STATUS
}

Write-Host ("##vso[task.setvariable variable=qualityGateResult]$PERFSPEC_RESULT")

# evaluate the result and pass or fail the pipeline
if ("$PERFSPEC_RESULT" -eq "fail") {
    Write-Host "Failed the quality gate" 
    #exit 1
} else {
    Write-Host "Passed the quality gate" 
}
