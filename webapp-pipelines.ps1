######### variables ###########

$rsgName = ".Netcore-webapp"
$regionName = "westeurope"
$appName = "CI-CD-webapp"
$planName = "webPlan"
$servicePlan = "FREE"
$org = "arthurtaragola"
$uri = "https://dev.azure.com/$org"
$agentPool = "Default"
$repo = 'https://github.com/ArthurTaragola/sampleWebapp'
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

#get agent
#az pipelines pool list --pool-name $agentPool --organization $uri
#az pipelines agent list --pool-id 10  --organization $uri
# az vm run-command invoke  --command-id RunPowerShellScript --name win-vm -g my-resource-group \

#create pipeline CI
az pipelines create --organization $uri `
                    --project $project `
                    --name 'webapp' `
                    --description 'Pipeline for CI of a .net core webapp' `
                    --repository $repo --branch master `
                    --yml-path azure-pipelines.yml

#create release pipeline CD
#trigger release pipeline
# az pipelines release create --organization $uri `
#                             --project $project `
#                             --definition-name 'New release pipeline'

