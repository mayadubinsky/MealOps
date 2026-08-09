# Stop the script when a PowerShell command throws an error.
$ErrorActionPreference = "Stop"


# ============================================================
# Paths
# ============================================================

# Folder where this script is located:
# C:\Users\maya\MealOps\scripts
$ScriptsDir = $PSScriptRoot

# Go one directory up:
# C:\Users\maya\MealOps
$ProjectRoot = Split-Path -Parent $ScriptsDir

# Project folders.
$TerraformDir = Join-Path $ProjectRoot "terraform\infra"
$KubernetesDir = Join-Path $ProjectRoot "kubernetes"

Write-Host "Scripts directory:    $ScriptsDir"
Write-Host "Project root:         $ProjectRoot"
Write-Host "Terraform directory:  $TerraformDir"
Write-Host "Kubernetes directory: $KubernetesDir"

# ============================================================
# Configuration
# ============================================================

# Name of the Docker image that already exists locally.
$ImageName = "mealops"

# Kubernetes resource names.
$DeploymentName = "mealops"
$ServiceName = "mealops"
$SecretName = "mealops-ai-secret"

# Number of main startup steps.
$TotalSteps = 6


# ============================================================
# Helper functions
# ============================================================

function Write-Step {
    param (
        [int]$Number,
        [string]$Message
    )

    Write-Host ""
    Write-Host "[$Number/$TotalSteps] $Message"
}

function Write-Success {
    param (
        [string]$Message
    )

    Write-Host "      $Message - OK"
}


# ============================================================
# Start
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "       MealOps Environment Startup"
Write-Host "========================================"


# ============================================================
# Validate Gemini API key
# ============================================================

# The API key should not be stored in this script or committed
# to Git.
#
# Before running this script, it should be available as:
#
# $env:GEMINI_API_KEY="your-api-key"
#
# Stop the script if it doesn't exist.
if (-not $env:GEMINI_API_KEY) {
    Write-Host ""
    Write-Host "ERROR: GEMINI_API_KEY environment variable is not set."
    Write-Host ""
    Write-Host "Set it first with:"
    Write-Host '$env:GEMINI_API_KEY="your-api-key"'

    exit 1
}


# ============================================================
# Validate local Docker image
# ============================================================

# We are NOT building the image in this script.
# The image should already exist locally as mealops:latest.
$LocalImage = "${ImageName}:latest"

docker image inspect $LocalImage *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Local Docker image '$LocalImage' does not exist. Build the image before running this script."
}


# ============================================================
# 1. Create Azure infrastructure
# ============================================================

Write-Step 1 "Creating Azure infrastructure..."

# Temporarily move into terraform/infra.
#
# Push-Location remembers the current directory so we can return
# to it later with Pop-Location.
Push-Location $TerraformDir


# Initialize Terraform.
#
# Running terraform init again is safe and makes sure the
# backend and providers are ready.
terraform init

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform init failed."
}


# Create the Azure infrastructure.
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform apply failed."
}

Write-Success "Azure infrastructure created"


# ============================================================
# Read values from Terraform
# ============================================================

Write-Host ""
Write-Host "      Reading Terraform outputs..."


# Terraform is the source of truth for the Azure resource names.
#
# This means we do not hard-code the actual AKS, ACR, or
# Resource Group names in the PowerShell script.
$AksName = terraform output -raw aks_name
$ResourceGroup = terraform output -raw resource_group_name
$AcrName = terraform output -raw acr_name


# Return to the directory from which the script was started.
Pop-Location


Write-Host "      AKS:            $AksName"
Write-Host "      Resource Group: $ResourceGroup"
Write-Host "      ACR:            $AcrName"


# ============================================================
# 2. Connect kubectl to AKS
# ============================================================

Write-Step 2 "Connecting kubectl to AKS..."


# Because Terraform recreated the AKS cluster, retrieve its
# Kubernetes credentials again.
#
# --overwrite-existing replaces the previous kubeconfig entry
# if one already exists with the same cluster name.
az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $AksName `
    --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    throw "Failed to get AKS credentials."
}


# Verify that kubectl can communicate with the cluster.
kubectl cluster-info

if ($LASTEXITCODE -ne 0) {
    throw "kubectl cannot connect to the AKS cluster."
}

Write-Success "Connected to AKS"


# ============================================================
# 3. Push existing image to ACR
# ============================================================

Write-Step 3 "Pushing MealOps image to ACR..."


# Login Docker to Azure Container Registry.
az acr login --name $AcrName

if ($LASTEXITCODE -ne 0) {
    throw "ACR login failed."
}


# Build the complete ACR image name.
#
# Example:
#
# mealopsacr.azurecr.io/mealops:latest
$RemoteImage = "${AcrName}.azurecr.io/${ImageName}:latest"


Write-Host "      Local image:  $LocalImage"
Write-Host "      Remote image: $RemoteImage"


# Tag the existing local image with the ACR address.
#
# This does NOT rebuild the image.
#
# It only gives the existing Docker image another name/tag.
docker tag $LocalImage $RemoteImage

if ($LASTEXITCODE -ne 0) {
    throw "Docker tag failed."
}


# Push the image to Azure Container Registry.
docker push $RemoteImage

if ($LASTEXITCODE -ne 0) {
    throw "Docker push failed."
}

Write-Success "MealOps image pushed to ACR"


# ============================================================
# 4. Create Kubernetes Secret
# ============================================================

Write-Step 4 "Creating Kubernetes Secret..."


# Generate the Secret YAML locally.
#
# --dry-run=client
#     Generates the Secret without creating it.
#
# -o yaml
#     Returns the generated Secret as YAML.
#
# We then pipe that YAML into:
#
# kubectl apply -f -
#
# This makes the operation safe to run repeatedly:
#
# Secret doesn't exist -> create it
# Secret exists        -> update it
$SecretYaml = kubectl create secret generic $SecretName `
    --from-literal=GEMINI_API_KEY=$env:GEMINI_API_KEY `
    --dry-run=client `
    -o yaml

if ($LASTEXITCODE -ne 0) {
    throw "Failed to generate Kubernetes Secret."
}


# Apply the generated Secret to Kubernetes.
$SecretYaml | kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply Kubernetes Secret."
}

Write-Success "Kubernetes Secret created"


# ============================================================
# 5. Deploy Kubernetes resources
# ============================================================

Write-Step 5 "Deploying MealOps to Kubernetes..."


# Apply the resources defined by kubernetes/kustomization.yaml.
#
# Kustomize handles the Deployment, Service, ConfigMap,
# and any other resources listed there.
kubectl apply -k $KubernetesDir

if ($LASTEXITCODE -ne 0) {
    throw "kubectl apply failed."
}


# ============================================================
# Wait for Deployment
# ============================================================

Write-Host ""
Write-Host "      Waiting for MealOps Deployment to become ready..."


# Wait for Kubernetes to finish creating/updating the pods.
#
# If the Deployment does not become ready within 5 minutes,
# the command fails.
kubectl rollout status `
    deployment/$DeploymentName `
    --timeout=300s

if ($LASTEXITCODE -ne 0) {

    # Print useful troubleshooting information before stopping.
    Write-Host ""
    Write-Host "Deployment did not become ready."
    Write-Host ""

    Write-Host "Pods:"
    kubectl get pods

    Write-Host ""

    Write-Host "Deployment:"
    kubectl get deployment $DeploymentName

    throw "MealOps Deployment failed."
}

Write-Success "MealOps Deployment is ready"


# ============================================================
# 6. Wait for LoadBalancer external IP
# ============================================================

Write-Step 6 "Waiting for LoadBalancer external IP..."


$ExternalIP = ""


# Azure may need some time to create the LoadBalancer and
# assign its public IP.
#
# Check every 10 seconds, up to 30 times.
#
# Maximum wait:
# about 5 minutes.
for ($i = 1; $i -le 30; $i++) {

    # Read the external IP directly from the Kubernetes Service.
    $ExternalIP = kubectl get service $ServiceName `
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

    if ($ExternalIP) {
        break
    }

    Write-Host "      Waiting for Azure LoadBalancer..."

    Start-Sleep -Seconds 10
}


# ============================================================
# Final status
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "          MealOps is running"
Write-Host "========================================"

Write-Host ""


# Show current pod status.
Write-Host "Pods:"
kubectl get pods


Write-Host ""


# Show current Service status.
Write-Host "Services:"
kubectl get services


Write-Host ""


# Show the Docker image that was deployed.
Write-Host "Image:"
Write-Host "$RemoteImage"


Write-Host ""


# Print the MealOps URL if Azure already assigned the
# LoadBalancer IP.
if ($ExternalIP) {

    Write-Host "MealOps URL:"
    Write-Host "http://${ExternalIP}:8000"

}
else {

    Write-Host "MealOps was deployed successfully, but Azure has"
    Write-Host "not assigned the LoadBalancer an external IP yet."

    Write-Host ""
    Write-Host "Check it with:"
    Write-Host "kubectl get service $ServiceName"
}


Write-Host ""
Write-Host "========================================"
Write-Host " Startup completed successfully"
Write-Host "========================================"