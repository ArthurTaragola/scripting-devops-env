######### variables ###########

$downloadUri = "https://vstsagentpackage.azureedge.net/agent/2.179.0/vsts-agent-win-x64-2.179.0.zip"
$agentFoler = "c:\agent"
$user = ""
$org = ""
$uri = "https://dev.azure.com/$org"
$token = ""
$agentPool = "Default"

###############################

#region - Display system information
$hostName = (Get-CimInstance Win32_ComputerSystem).Name
$OS = Get-CimInstance Win32_OperatingSystem | Select-Object Caption

#region - Check connection to Azure devops
Write-Host "Checking connection to Azure devops..."
$conStatus = Invoke-WebRequest -Uri $uri | Select-Object StatusCode
Write-Host $conStatus | Out-String -Stream 
if($conStatus.StatusCode -eq 203 ){
    Write-Host "Succesfuly connected to Azure Devops!"
 }else {
    Write-Host "Error connecting to Azure Devops"
    #exit 
 }
#endregion

#region - Download Agent assets
Set-Location -Path C:\Users\$user\Downloads
Write-Host "Downloading agent assets..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $downloadUri -OutFile windows-x64-agent.zip
New-Item -Type Directory -Path $agentFoler -ErrorAction Ignore
Expand-Archive -LiteralPath .\windows-x64-agent.zip -DestinationPath $agentFoler
#endregion

#region - Register Agent
Set-Location $agentFoler
.\config.cmd --unattended --url $uri --auth pat --token $token --pool $agentPool --agent $hostName --replace --runAsService
#endregion

