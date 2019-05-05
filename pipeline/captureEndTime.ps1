$endTime = Get-Date -UFormat %s
$endTimeFormatted = Get-Date -UFormat "%x %R"

Write-Host "==============================================================="
Write-Host "End Time: "$endTime
Write-Host "End Time Formatted: "$endTimeFormatted
Write-Host "==============================================================="

Write-Host ("##vso[task.setvariable variable=endTimeFormatted]$endTimeFormatted")
Write-Host ("##vso[task.setvariable variable=endTime]$endTime")
