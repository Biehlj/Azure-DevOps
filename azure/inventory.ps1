# Connect to Azure
try {
    Write-Host "Connecting to Azure..."
    Connect-AzAccount
} catch {
    Write-Error "Unable to connect to Azure. Please check your credentials and try again."
    exit 1
}

# Set the Azure subscription
try {
    Write-Host "Setting the Azure subscription..."
    Set-AzContext -SubscriptionId (Get-AzKeyVaultSecret -VaultName $env:VAULT_NAME -Name $env:SUBSCRIPTION_ID).SecretValueText
} catch {
    Write-Error "Unable to set the Azure subscription. Please check your credentials and try again."
    exit 1
}

# Create a resource group if it doesn't exist
$resourceGroupName = $env:RESOURCE_GROUP_NAME
$location = $env:RESOURCE_GROUP_LOCATION
if (Get-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue) {
    Write-Host "Resource group '$resourceGroupName' already exists."
} else {
    Write-Host "Creating resource group '$resourceGroupName' in '$location'..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create a container instance if it doesn't exist default image is mcr.microsoft.com/windows/servercore:ltsc2022
$containerName = $env:CONTAINER_NAME
$image = "mcr.microsoft.com/windows/servercore:ltsc2022"
$containerPort = 80
Write-Host "Do you want to use a custom container image? (y/n)"
$response = Read-Host
if ($response -eq "y") {
    Write-Host "Enter the container image name:"
    $image = Read-Host
    
    # Check if the container image exists
    $imageExists = Get-AzContainerRegistryImage -RegistryName $env:CONTAINER_REGISTRY_NAME -Repository $env:CONTAINER_IMAGE_NAME -ErrorAction SilentlyContinue
    if ($imageExists) {
       Write-Host "Container image '$env:CONTAINER_IMAGE_NAME' exists in container registry '$env:CONTAINER_REGISTRY_NAME'."
    } else {
       Write-Error "Container image '$env:CONTAINER_IMAGE_NAME' does not exist in container registry '$env:CONTAINER_REGISTRY_NAME'. Please check the image name and try again."
       exit 1
    }
}
Write-Host "Checking if container instance '$containerName' exists..."
if(Get-AzContainerGroup -ResourceGroupName $resourceGroupName -Name $containerName -ErrorAction SilentlyContinue) {
    Write-Host "Container instance '$containerName' already exists. Do you want to recreate it? (y/n)"
    $response = Read-Host
    if ($response -eq "y") {
        Write-Host "Deleting container instance '$containerName'..."
        Remove-AzContainerGroup -ResourceGroupName $resourceGroupName -Name $containerName -Force
        Write-Host "Creating container instance '$containerName'..."
        $resource = New-AzContainerGroup -ResourceGroupName $resourceGroupName -Name $containerName -Image $image -Port $containerPort -OsType Windows
    } else {
        Write-Host "Skipping container instance creation."
    }
} else {
    Write-Host "Creating container instance '$containerName'..."
    $resource = New-AzContainerGroup -ResourceGroupName $resourceGroupName -Name $containerName -Image $image -Port $containerPort -OsType Windows
}

# Get the container instance details
$resource

