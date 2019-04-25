$startTime = Get-Date -UFormat %s
$startTimeFormatted = Get-Date -UFormat "%x %R"

Write-Host "==============================================================="
Write-Host "Start Time: "$startTime
Write-Host "Start Time Formatted: "$startTimeFormatted
Write-Host "==============================================================="

Write-Host ("##vso[task.setvariable variable=startTimeFormatted]$startTimeFormatted")
Write-Host ("##vso[task.setvariable variable=startTime]$startTime")
