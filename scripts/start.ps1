# Stop the script when a PowerShell command throws an error.
$ErrorActionPreference = "Stop"


# ============================================================
# Paths
# ============================================================

# $PSScriptRoot is an automatic PowerShell variable that
# contains the directory where this script is located.
#
# Example:
# C:\Users\maya\MealOps\scripts
$ScriptsDir = $PSScriptRoot

# Go one directory up to get the MealOps repository root.
#
# Result:
# C:\Users\maya\MealOps
$ProjectRoot = Split-Path -Parent $ScriptsDir

# Disposable Terraform infrastructure.
$InfraDir = Join-Path $ProjectRoot "terraform\infra"

# Argo CD Application manifests.
$ProdApplicationFile = Join-Path `
    $ProjectRoot `
    "argocd\mealops-prod-application.yaml"

$DevApplicationFile = Join-Path `
    $ProjectRoot `
    "argocd\mealops-dev-application.yaml"


# ============================================================
# Configuration
# ============================================================

# Kubernetes resource names.
$DeploymentName = "mealops"
$ServiceName = "mealops"
$SecretName = "mealops-ai-secret"

# Kubernetes namespaces.
$ProdNamespace = "mealops-prod"
$DevNamespace = "mealops-dev"
$ArgoNamespace = "argocd"

# Argo CD Application names.
$ProdApplicationName = "mealops-prod"
$DevApplicationName = "mealops-dev"

# Official Argo CD installation manifest.
$ArgoInstallUrl = `
    "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

# Number of main startup steps.
$TotalSteps = 8


# ============================================================
# Helper functions
# ============================================================

# Print the current startup step.
function Write-Step {
    param (
        [int]$Number,
        [string]$Message
    )

    Write-Host ""
    Write-Host "[$Number/$TotalSteps] $Message"
}


# Print a success message.
function Write-Success {
    param (
        [string]$Message
    )

    Write-Host "      $Message - OK"
}


# Create/update a Kubernetes namespace.
#
# dry-run + apply makes this idempotent:
#
# namespace missing -> create it
# namespace exists  -> keep/update it
function Ensure-Namespace {
    param (
        [string]$Namespace
    )

    $NamespaceYaml = kubectl create namespace $Namespace `
        --dry-run=client `
        -o yaml

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate namespace '$Namespace'."
    }

    $NamespaceYaml | kubectl apply -f -

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply namespace '$Namespace'."
    }
}


# Create/update the Gemini API Secret in a namespace.
#
# Secrets are namespace-scoped, so dev and prod each need
# their own copy of mealops-ai-secret.
function Ensure-MealOpsSecret {
    param (
        [string]$Namespace
    )

    Write-Host "      Creating Secret in '$Namespace'..."

    $SecretYaml = kubectl create secret generic $SecretName `
        --namespace $Namespace `
        --from-literal=GEMINI_API_KEY=$env:GEMINI_API_KEY `
        --dry-run=client `
        -o yaml

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate Secret in '$Namespace'."
    }

    $SecretYaml | kubectl apply -f -

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply Secret in '$Namespace'."
    }
}


# Wait until Argo CD creates the MealOps Deployment.
function Wait-ForDeploymentCreation {
    param (
        [string]$Namespace,
        [string]$ApplicationName
    )

    for ($i = 1; $i -le 60; $i++) {

        # Check whether the Deployment exists.
        #
        # Redirect both stdout and stderr so that a normal
        # "NotFound" response does not stop the PowerShell script.
        kubectl get deployment $DeploymentName `
            -n $Namespace `
            *> $null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "      Deployment/$DeploymentName found."
            return
        }

        Write-Host `
            "      Waiting for Argo CD Application '$ApplicationName' to create Deployment/$DeploymentName..."

        Start-Sleep -Seconds 5
    }

    # If the Deployment still does not exist after 5 minutes,
    # print useful Argo information before failing.
    Write-Host ""
    Write-Host "Argo CD Application status:"

    kubectl get application $ApplicationName `
        -n $ArgoNamespace `
        -o wide

    Write-Host ""
    Write-Host "Argo CD Application details:"

    kubectl describe application $ApplicationName `
        -n $ArgoNamespace

    throw "Argo CD did not create Deployment/$DeploymentName in namespace '$Namespace'."
}

# Wait until the MealOps Deployment becomes Ready.
function Wait-ForMealOpsDeployment {
    param (
        [string]$Namespace
    )

    kubectl rollout status `
        deployment/$DeploymentName `
        -n $Namespace `
        --timeout=300s

    if ($LASTEXITCODE -eq 0) {
        return
    }

    # If the rollout starts but the Pods do not become Ready,
    # Kubernetes can eventually report that the Deployment
    # exceeded its progress deadline.
    #
    # Restart the Deployment so Kubernetes creates fresh Pods.
    Write-Host ""
    Write-Host "      Rollout failed in '$Namespace'."
    Write-Host "      Restarting Deployment..."

    kubectl rollout restart `
        deployment/$DeploymentName `
        -n $Namespace

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to restart Deployment in '$Namespace'."
    }

    Write-Host "      Waiting for restarted Deployment..."

    kubectl rollout status `
        deployment/$DeploymentName `
        -n $Namespace `
        --timeout=300s

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "Pods in '$Namespace':"
        kubectl get pods -n $Namespace

        Write-Host ""
        Write-Host "Deployment:"
        kubectl get deployment $DeploymentName `
            -n $Namespace

        throw "MealOps Deployment failed in namespace '$Namespace'."
    }
}


# Wait for the public IP of a LoadBalancer Service.
function Get-LoadBalancerIP {
    param (
        [string]$Namespace
    )

    for ($i = 1; $i -le 30; $i++) {

        $IP = kubectl get service $ServiceName `
            -n $Namespace `
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' `
            2>$null

        if ($IP) {
            return $IP
        }

        Write-Host "      Waiting for LoadBalancer in '$Namespace'..."

        Start-Sleep -Seconds 10
    }

    return ""
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

# The API key must stay outside Git.
#
# Before running this script:
#
# $env:GEMINI_API_KEY="your-api-key"
if (-not $env:GEMINI_API_KEY) {

    Write-Host ""
    Write-Host "ERROR: GEMINI_API_KEY is not set."
    Write-Host ""
    Write-Host "Set it with:"
    Write-Host '$env:GEMINI_API_KEY="your-api-key"'

    exit 1
}


# ============================================================
# Validate required files
# ============================================================

if (-not (Test-Path $ProdApplicationFile)) {
    throw "Missing file: $ProdApplicationFile"
}

if (-not (Test-Path $DevApplicationFile)) {
    throw "Missing file: $DevApplicationFile"
}


# ============================================================
# Determine current development branch
# ============================================================

# Prod always follows main.
#
# Dev follows whichever feature branch is currently checked
# out locally.
#
# Argo CD reads from the REMOTE Git repository, so the branch
# must already exist on origin.
Push-Location $ProjectRoot

$DevBranch = git branch --show-current

if ($LASTEXITCODE -ne 0 -or -not $DevBranch) {
    Pop-Location
    throw "Could not determine the current Git branch."
}


$RemoteBranch = git ls-remote `
    --heads `
    origin `
    "refs/heads/$DevBranch"

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "Could not query Git origin."
}


if (-not $RemoteBranch) {

    Pop-Location

    Write-Host ""
    Write-Host "ERROR:"
    Write-Host "Branch '$DevBranch' does not exist on origin."
    Write-Host ""
    Write-Host "Push it first with:"
    Write-Host "git push -u origin $DevBranch"

    exit 1
}

Pop-Location


Write-Host ""
Write-Host "GitOps:"
Write-Host "      PROD -> main"
Write-Host "      DEV  -> $DevBranch"


# ============================================================
# 1. Create disposable Azure infrastructure
# ============================================================

Write-Step 1 "Creating AKS runtime infrastructure..."

Push-Location $InfraDir


# Initialize Terraform backend/providers.
terraform init

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform init failed for infra."
}


# Create the disposable runtime infrastructure.
#
# ACR is NOT part of this Terraform state anymore.
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform apply failed for infra."
}


# Read values from Terraform outputs.
$AksName = terraform output -raw aks_name
$ResourceGroup = terraform output -raw resource_group_name


if (-not $AksName) {
    Pop-Location
    throw "Terraform output 'aks_name' is empty."
}

if (-not $ResourceGroup) {
    Pop-Location
    throw "Terraform output 'resource_group_name' is empty."
}


Pop-Location


Write-Host "      AKS:            $AksName"
Write-Host "      Resource Group: $ResourceGroup"

Write-Success "AKS runtime infrastructure created"


# ============================================================
# 2. Connect kubectl to AKS
# ============================================================

Write-Step 2 "Connecting kubectl to AKS..."


# Retrieve credentials for the newly created AKS cluster.
az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $AksName `
    --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    throw "Failed to retrieve AKS credentials."
}


# Verify that kubectl can communicate with AKS.
kubectl cluster-info

if ($LASTEXITCODE -ne 0) {
    throw "kubectl cannot communicate with AKS."
}


Write-Success "Connected to AKS"


# ============================================================
# 3. Create Kubernetes namespaces
# ============================================================

Write-Step 3 "Creating Kubernetes namespaces..."


Ensure-Namespace $ProdNamespace
Ensure-Namespace $DevNamespace
Ensure-Namespace $ArgoNamespace


Write-Success "Namespaces ready"


# ============================================================
# 4. Create MealOps Secrets
# ============================================================

Write-Step 4 "Creating MealOps Kubernetes Secrets..."


Ensure-MealOpsSecret $ProdNamespace
Ensure-MealOpsSecret $DevNamespace


Write-Success "MealOps Secrets ready"


# ============================================================
# 5. Install Argo CD
# ============================================================

Write-Step 5 "Installing Argo CD..."


# Server-side apply means the Kubernetes API server performs
# the apply operation and tracks field ownership.
#
# We use it here because Argo CD contains large CRDs.
# Normal client-side apply stores the previous configuration
# in the kubectl.kubernetes.io/last-applied-configuration
# annotation, which caused the 262144-byte annotation limit
# error with the ApplicationSet CRD.
kubectl apply `
    --server-side `
    -n $ArgoNamespace `
    -f $ArgoInstallUrl

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD installation failed."
}


# Wait until Kubernetes registers the Argo Application CRD.
Write-Host ""
Write-Host "      Waiting for Argo CD Application CRD..."

kubectl wait `
    --for=condition=Established `
    crd/applications.argoproj.io `
    --timeout=120s

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD Application CRD did not become ready."
}


# Wait for Argo CD Deployments.
Write-Host ""
Write-Host "      Waiting for Argo CD Deployments..."

kubectl wait `
    --for=condition=Available `
    deployment `
    --all `
    -n $ArgoNamespace `
    --timeout=300s

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "Argo CD pods:"
    kubectl get pods -n $ArgoNamespace

    throw "Argo CD Deployments did not become ready."
}


# The Application Controller runs as a StatefulSet.
kubectl rollout status `
    statefulset/argocd-application-controller `
    -n $ArgoNamespace `
    --timeout=300s

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "Argo CD pods:"
    kubectl get pods -n $ArgoNamespace

    throw "Argo CD Application Controller did not become ready."
}


Write-Success "Argo CD installed and ready"


# ============================================================
# 6. Create prod and dev Argo CD Applications
# ============================================================

Write-Step 6 "Creating MealOps Argo CD Applications..."


# ------------------------------------------------------------
# PROD
# ------------------------------------------------------------
#
# The prod Application manifest should contain:
#
# targetRevision: main
# path: kubernetes/overlays/prod
# namespace: mealops-prod
kubectl apply -f $ProdApplicationFile

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create MealOps prod Argo Application."
}


Write-Host "      PROD -> main"


# ------------------------------------------------------------
# DEV
# ------------------------------------------------------------
#
# The dev Application manifest should contain:
#
# targetRevision: BRANCH_PLACEHOLDER
#
# The placeholder is replaced IN MEMORY with the branch that
# is currently checked out.
#
# The file itself is not modified.
$DevApplicationYaml = Get-Content `
    $DevApplicationFile `
    -Raw


if (-not $DevApplicationYaml.Contains("BRANCH_PLACEHOLDER")) {
    throw "Dev Argo Application manifest is missing BRANCH_PLACEHOLDER."
}


$DevApplicationYaml = $DevApplicationYaml.Replace(
    "BRANCH_PLACEHOLDER",
    $DevBranch
)


$DevApplicationYaml | kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create MealOps dev Argo Application."
}


Write-Host "      DEV  -> $DevBranch"

Write-Success "Argo CD Applications created"


# ============================================================
# 7. Wait for Argo CD to deploy MealOps
# ============================================================

Write-Step 7 "Waiting for Argo CD to deploy prod and dev..."


# ------------------------------------------------------------
# PROD
# ------------------------------------------------------------

Write-Host ""
Write-Host "      Waiting for PROD Deployment..."

Wait-ForDeploymentCreation `
    $ProdNamespace `
    $ProdApplicationName


Wait-ForMealOpsDeployment `
    $ProdNamespace


Write-Success "MealOps PROD is ready"


# ------------------------------------------------------------
# DEV
# ------------------------------------------------------------

Write-Host ""
Write-Host "      Waiting for DEV Deployment..."

Wait-ForDeploymentCreation `
    $DevNamespace `
    $DevApplicationName


Wait-ForMealOpsDeployment `
    $DevNamespace


Write-Success "MealOps DEV is ready"


# ============================================================
# 8. Wait for LoadBalancer IPs
# ============================================================

Write-Step 8 "Waiting for LoadBalancer external IPs..."


Write-Host ""
Write-Host "      PROD:"

$ProdExternalIP = Get-LoadBalancerIP `
    $ProdNamespace


Write-Host ""
Write-Host "      DEV:"

$DevExternalIP = Get-LoadBalancerIP `
    $DevNamespace


# ============================================================
# Final status
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "          MealOps is running"
Write-Host "========================================"


# ------------------------------------------------------------
# Argo CD Applications
# ------------------------------------------------------------

Write-Host ""
Write-Host "Argo CD Applications:"

kubectl get applications `
    -n $ArgoNamespace


# ------------------------------------------------------------
# PROD
# ------------------------------------------------------------

Write-Host ""
Write-Host "PROD Pods:"

kubectl get pods `
    -n $ProdNamespace


Write-Host ""
Write-Host "PROD Services:"

kubectl get services `
    -n $ProdNamespace


# ------------------------------------------------------------
# DEV
# ------------------------------------------------------------

Write-Host ""
Write-Host "DEV Pods:"

kubectl get pods `
    -n $DevNamespace


Write-Host ""
Write-Host "DEV Services:"

kubectl get services `
    -n $DevNamespace


# ------------------------------------------------------------
# GitOps sources
# ------------------------------------------------------------

Write-Host ""
Write-Host "GitOps sources:"
Write-Host "      PROD -> main"
Write-Host "      DEV  -> $DevBranch"


# ------------------------------------------------------------
# URLs
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host "              URLs"
Write-Host "========================================"


if ($ProdExternalIP) {

    Write-Host ""
    Write-Host "PROD:"
    Write-Host "http://${ProdExternalIP}"

}
else {

    Write-Host ""
    Write-Host "PROD:"
    Write-Host "External IP is not available yet."
}


if ($DevExternalIP) {

    Write-Host ""
    Write-Host "DEV:"
    Write-Host "http://${DevExternalIP}"

}
else {

    Write-Host ""
    Write-Host "DEV:"
    Write-Host "External IP is not available yet."
}
# ============================================================
# Argo CD login information
# ============================================================

# A fresh Argo CD installation generates an initial password
# for the built-in "admin" user.
#
# The password is stored in the Kubernetes Secret:
#
# argocd-initial-admin-secret
#
# Kubernetes Secrets store their values as Base64, so we:
# 1. Read the password field from the Secret.
# 2. Decode it from Base64 into normal text.

Write-Host ""
Write-Host "========================================"
Write-Host "          Argo CD Login"
Write-Host "========================================"

$ArgoPasswordBase64 = kubectl get secret `
    argocd-initial-admin-secret `
    -n $ArgoNamespace `
    -o jsonpath='{.data.password}'

if ($LASTEXITCODE -eq 0 -and $ArgoPasswordBase64) {

    $ArgoPassword = [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String($ArgoPasswordBase64)
    )

    Write-Host ""
    Write-Host "Username: admin"
    Write-Host "Password: $ArgoPassword"
}
else {
    Write-Host ""
    Write-Host "Could not retrieve the Argo CD initial admin password."
}

Write-Host ""
Write-Host "========================================"
Write-Host " Startup completed successfully"
Write-Host "========================================"