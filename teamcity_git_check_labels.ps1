$Token = ''

$Base64Token = [System.Convert]::ToBase64String([char[]]$Token);

# Ensures that Invoke-WebRequest uses TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:gitHubApiReposUrl = "https://api.github.com/repos"
$ownerName = 'vokidoki2016'
$repositoryName = 'WebAppCore'
$pullnumber = '49'

$query = "$script:gitHubApiReposUrl/{0}/{1}/pulls/{2}" -f $ownerName, $repositoryName, $pullnumber

$Headers = @{
     Authorization = 'Basic {0}' -f $Base64Token;
     };

$jsonResult = Invoke-WebRequest $query -UseBasicParsing -Method Get -Headers $Headers

$labels = ConvertFrom-Json -InputObject $jsonResult.content | Select -expand Labels | select -ExpandProperty Name

Write-Output $labels

foreach ($label in $labels) 
{
  if ($label -eq "work in progress" -or $label -eq "do not merge" -or $label -eq "merge conflicts") {
     Write-Output "PR stopped build because it have the special label"
     exit 1
  }  
}
Write-Output "Ready to build"