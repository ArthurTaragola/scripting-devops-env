######### variables ###########

$rsgName = ".Netcore-webapp"
$regionName = "westeurope"
$appName = "CI-CD-webapp"
$planName = "webPlan"
$servicePlan = "FREE"
$org = ""
$uri = "https://dev.azure.com/$org"
$poolId = 1
$agentId = 13
$repo = 'https://github.com/xxx/sampleWebapp'
$project = 'Research'

###############################

### configure AZ cli
#az config set extension.use_dynamic_install=yes_without_prompt

### Making Recources

#check if Recource group exists
$rsgExists = az group exists -n $rsgName
if ($rsgExists -eq 'false') {
    Write-Host "Making Recource group $rsgName ..."
    az group create -l $regionName -n $rsgName
    az configure --defaults group=$rsgName location=$regionName
}
else {
    Write-Host "Recource group $rsgName exists!"
    az configure --defaults group=$rsgName location=$regionName
}

#create app service plan
Write-Host "Creating service plan ..."
az appservice plan create --name $planName --sku $servicePlan
Write-Host "Creating web app ..."
az webapp create --name $appName --plan $planName -g $rsgName --runtime "DOTNETCORE 3.1"

### Pipelines

#see agent pool
az pipelines pool show --id $poolId --output table --organization $uri

$continue = $true
while($continue)
{
    $agentObj = az pipelines agent show --pool-id $poolId --agent-id $agentId --organization $uri | ConvertFrom-Json
    $agentStatus = $agentObj.status

    if ($agentStatus -eq 'online') {

        #create pipeline CI
        az pipelines create --organization $uri `
                            --project $project `
                            --name 'webapp' `
                            --description 'Pipeline for CI of a .net core webapp' `
                            --repository $repo --branch master `
                            --yml-path azure-pipelines.yml        
        $continue = $false
    }
    else {
        Write-Host "Waiting for agent to come online ..."
        Start-Sleep 60.0
    }
}

