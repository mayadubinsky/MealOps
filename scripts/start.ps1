# Stop the script when a PowerShell command throws an error.
$ErrorActionPreference = "Stop"


# ============================================================
# Paths
# ============================================================

# $PSScriptRoot is an automatic PowerShell variable containing
# the directory of the currently running script.
#
# Example:
# C:\Users\maya\MealOps\scripts
$ScriptsDir = $PSScriptRoot

# Go one directory up to get the repository root.
$ProjectRoot = Split-Path -Parent $ScriptsDir

# Terraform stacks.
$RegistryDir = Join-Path $ProjectRoot "terraform\registry"
$InfraDir    = Join-Path $ProjectRoot "terraform\infra"

# Argo CD Application manifests.
$ProdApplicationFile = Join-Path `
    $ProjectRoot `
    "argocd\mealops-prod-application.yaml"

$DevApplicationFile = Join-Path `
    $ProjectRoot `
    "argocd\mealops-dev-application.yaml"

# Kustomize overlays.
$ProdOverlayFile = Join-Path `
    $ProjectRoot `
    "kubernetes\overlays\prod\kustomization.yaml"

$DevOverlayFile = Join-Path `
    $ProjectRoot `
    "kubernetes\overlays\dev\kustomization.yaml"


# ============================================================
# Configuration
# ============================================================

$ImageName = "mealops"

# Temporary image used until CI starts creating commit-SHA tags.
$BootstrapTag = "bootstrap"

# Existing local image used only for first-time bootstrap.
$LocalImage = "${ImageName}:latest"

# Kubernetes resource names.
$DeploymentName = "mealops"
$ServiceName    = "mealops"
$SecretName     = "mealops-ai-secret"

# Namespaces.
$ProdNamespace  = "mealops-prod"
$DevNamespace   = "mealops-dev"
$ArgoNamespace  = "argocd"

# Argo Applications.
$ProdApplicationName = "mealops-prod"
$DevApplicationName  = "mealops-dev"

# Official Argo CD installation manifest.
$ArgoInstallUrl = `
    "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

$TotalSteps = 10


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


# Create/update a namespace.
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


# Create/update the MealOps Gemini Secret in a namespace.
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

        kubectl get deployment $DeploymentName `
            -n $Namespace *> $null

        if ($LASTEXITCODE -eq 0) {
            return
        }

        Write-Host `
            "      Waiting for Argo CD Application '$ApplicationName'..."

        Start-Sleep -Seconds 5
    }

    Write-Host ""
    Write-Host "Argo Application status:"

    kubectl get application $ApplicationName `
        -n $ArgoNamespace `
        -o wide

    throw "Argo did not create Deployment/$DeploymentName in '$Namespace'."
}


# Wait for the Deployment rollout.
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

    # A failed rollout doesn't necessarily mean the Deployment
    # itself is wrong.
    #
    # Print debugging information first.
    Write-Host ""
    Write-Host "Deployment did not become Ready in '$Namespace'."
    Write-Host ""

    Write-Host "Pods:"
    kubectl get pods -n $Namespace

    Write-Host ""

    Write-Host "Deployment:"
    kubectl get deployment $DeploymentName -n $Namespace

    throw "MealOps rollout failed in namespace '$Namespace'."
}


# Wait for a LoadBalancer external IP.
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

if (-not (Test-Path $ProdOverlayFile)) {
    throw "Missing file: $ProdOverlayFile"
}

if (-not (Test-Path $DevOverlayFile)) {
    throw "Missing file: $DevOverlayFile"
}


# ============================================================
# Determine current development branch
# ============================================================

Push-Location $ProjectRoot

$DevBranch = git branch --show-current

if ($LASTEXITCODE -ne 0 -or -not $DevBranch) {
    Pop-Location
    throw "Could not determine current Git branch."
}


# Argo reads the REMOTE repository, not your local files.
#
# Make sure the current branch exists on origin.
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
    Write-Host "Branch '$DevBranch' does not exist on origin."
    Write-Host ""
    Write-Host "Push it first:"
    Write-Host "git push -u origin $DevBranch"

    exit 1
}

Pop-Location


Write-Host ""
Write-Host "DEV branch: $DevBranch"


# ============================================================
# 1. Create / verify persistent ACR
# ============================================================

Write-Step 1 "Creating or verifying persistent ACR..."

Push-Location $RegistryDir


# registry has its own Terraform state.
terraform init

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform init failed for registry."
}


# First run:
#   creates ACR.
#
# Future mornings:
#   should normally return No changes.
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform apply failed for registry."
}


# Read ACR information from the registry stack.
$AcrName = terraform output -raw acr_name

if (-not $AcrName) {
    Pop-Location
    throw "Terraform registry output 'acr_name' is empty."
}


# Prefer Terraform's login_server output if you created it.
$AcrLoginServer = terraform output -raw acr_login_server

if (-not $AcrLoginServer) {
    Pop-Location
    throw "Terraform registry output 'acr_login_server' is empty."
}


Pop-Location


Write-Host "      ACR:          $AcrName"
Write-Host "      Login server: $AcrLoginServer"

Write-Success "Persistent ACR ready"


# ============================================================
# 2. Bootstrap initial image when needed
# ============================================================

Write-Step 2 "Checking bootstrap image..."


# Once CI exists, your overlays will contain commit SHA tags.
#
# Until then, both overlays can use:
#
# newTag: bootstrap
#
# If neither overlay uses bootstrap anymore, this entire
# section does nothing.
$ProdOverlayContent = Get-Content $ProdOverlayFile -Raw
$DevOverlayContent  = Get-Content $DevOverlayFile -Raw

$BootstrapRequired = `
    ($ProdOverlayContent -match "newTag:\s*$BootstrapTag") -or `
    ($DevOverlayContent -match "newTag:\s*$BootstrapTag")


if ($BootstrapRequired) {

    # Until CI exists, we need a first image in the new ACR.
    #
    # We use the already-tested local mealops:latest image.
    docker image inspect $LocalImage *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Bootstrap requires local Docker image '$LocalImage'."
    }


    Write-Host "      Bootstrap image is still used by Kustomize."
    Write-Host "      Pushing local image as '$BootstrapTag'..."


    az acr login --name $AcrName

    if ($LASTEXITCODE -ne 0) {
        throw "ACR login failed."
    }


    $BootstrapImage = `
        "${AcrLoginServer}/${ImageName}:${BootstrapTag}"


    docker tag `
        $LocalImage `
        $BootstrapImage

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to tag bootstrap image."
    }


    docker push $BootstrapImage

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push bootstrap image."
    }


    Write-Success "Bootstrap image pushed"
}
else {

    Write-Host "      Kustomize is using versioned images."
    Write-Host "      Bootstrap image not required."
}


# ============================================================
# 3. Create disposable Azure infrastructure
# ============================================================

Write-Step 3 "Creating AKS runtime infrastructure..."

Push-Location $InfraDir


terraform init

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform init failed for infra."
}


terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform apply failed for infra."
}


# Read the disposable infrastructure information.
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

Write-Success "AKS infrastructure created"


# ============================================================
# 4. Connect kubectl to AKS
# ============================================================

Write-Step 4 "Connecting kubectl to AKS..."


az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $AksName `
    --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    throw "Failed to retrieve AKS credentials."
}


kubectl cluster-info

if ($LASTEXITCODE -ne 0) {
    throw "kubectl cannot communicate with AKS."
}


Write-Success "Connected to AKS"


# ============================================================
# 5. Create namespaces
# ============================================================

Write-Step 5 "Creating Kubernetes namespaces..."


Ensure-Namespace $ProdNamespace
Ensure-Namespace $DevNamespace
Ensure-Namespace $ArgoNamespace


Write-Success "Namespaces ready"


# ============================================================
# 6. Create Secrets
# ============================================================

Write-Step 6 "Creating MealOps Secrets..."


# Secrets are namespace-scoped.
#
# Prod and dev each need their own Secret.
Ensure-MealOpsSecret $ProdNamespace
Ensure-MealOpsSecret $DevNamespace


Write-Success "Secrets ready"


# ============================================================
# 7. Install Argo CD
# ============================================================

Write-Step 7 "Installing Argo CD..."


# Server-side apply means the Kubernetes API server performs
# the apply operation and tracks field ownership.
#
# This avoids the huge client-side
# kubectl.kubernetes.io/last-applied-configuration annotation
# that caused the Argo CRD size error previously.
kubectl apply `
    --server-side `
    -n $ArgoNamespace `
    -f $ArgoInstallUrl

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD installation failed."
}


# Wait until the Application CRD exists.
kubectl wait `
    --for=condition=Established `
    crd/applications.argoproj.io `
    --timeout=120s

if ($LASTEXITCODE -ne 0) {
    throw "Argo CD Application CRD did not become ready."
}


Write-Host ""
Write-Host "      Waiting for Argo CD Deployments..."


kubectl wait `
    --for=condition=Available `
    deployment `
    --all `
    -n $ArgoNamespace `
    --timeout=300s

if ($LASTEXITCODE -ne 0) {

    kubectl get pods -n $ArgoNamespace

    throw "Argo CD Deployments did not become ready."
}


# The Argo Application Controller is a StatefulSet.
kubectl rollout status `
    statefulset/argocd-application-controller `
    -n $ArgoNamespace `
    --timeout=300s

if ($LASTEXITCODE -ne 0) {

    kubectl get pods -n $ArgoNamespace

    throw "Argo Application Controller did not become ready."
}


Write-Success "Argo CD ready"


# ============================================================
# 8. Create prod + dev Argo Applications
# ============================================================

Write-Step 8 "Creating Argo CD Applications..."


# ------------------------------------------------------------
# PROD
# ------------------------------------------------------------
#
# The prod manifest is static:
#
# branch: main
# path: kubernetes/overlays/prod
# namespace: mealops-prod
kubectl apply -f $ProdApplicationFile

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create prod Argo Application."
}


Write-Host "      PROD -> main"


# ------------------------------------------------------------
# DEV
# ------------------------------------------------------------
#
# The dev manifest contains:
#
# targetRevision: BRANCH_PLACEHOLDER
#
# Replace the placeholder IN MEMORY with the branch that is
# currently checked out locally.
#
# The YAML file itself is not changed.
$DevApplicationYaml = Get-Content `
    $DevApplicationFile `
    -Raw


if (-not $DevApplicationYaml.Contains("BRANCH_PLACEHOLDER")) {
    throw "Dev Argo manifest is missing BRANCH_PLACEHOLDER."
}


$DevApplicationYaml = $DevApplicationYaml.Replace(
    "BRANCH_PLACEHOLDER",
    $DevBranch
)


$DevApplicationYaml | kubectl apply -f -

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create dev Argo Application."
}


Write-Host "      DEV  -> $DevBranch"

Write-Success "Argo Applications created"


# ============================================================
# 9. Wait for MealOps
# ============================================================

Write-Step 9 "Waiting for Argo CD to deploy MealOps..."


# ------------------------------------------------------------
# PROD
# ------------------------------------------------------------

Write-Host ""
Write-Host "      Waiting for PROD..."

Wait-ForDeploymentCreation `
    $ProdNamespace `
    $ProdApplicationName

Wait-ForMealOpsDeployment `
    $ProdNamespace

Write-Success "PROD ready"


# ------------------------------------------------------------
# DEV
# ------------------------------------------------------------

Write-Host ""
Write-Host "      Waiting for DEV..."

Wait-ForDeploymentCreation `
    $DevNamespace `
    $DevApplicationName

Wait-ForMealOpsDeployment `
    $DevNamespace

Write-Success "DEV ready"


# ============================================================
# 10. Wait for LoadBalancer IPs
# ============================================================

Write-Step 10 "Waiting for LoadBalancer IPs..."


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


Write-Host ""
Write-Host "Argo CD Applications:"

kubectl get applications `
    -n $ArgoNamespace


Write-Host ""
Write-Host "PROD Pods:"

kubectl get pods `
    -n $ProdNamespace


Write-Host ""
Write-Host "DEV Pods:"

kubectl get pods `
    -n $DevNamespace


Write-Host ""
Write-Host "GitOps sources:"
Write-Host "      PROD -> main"
Write-Host "      DEV  -> $DevBranch"


Write-Host ""
Write-Host "Container Registry:"
Write-Host "      $AcrLoginServer"


Write-Host ""
Write-Host "========================================"
Write-Host "              URLs"
Write-Host "========================================"


if ($ProdExternalIP) {

    Write-Host ""
    Write-Host "PROD:"
    Write-Host "http://${ProdExternalIP}:8000"

}
else {

    Write-Host ""
    Write-Host "PROD:"
    Write-Host "External IP is not available yet."
}


if ($DevExternalIP) {

    Write-Host ""
    Write-Host "DEV:"
    Write-Host "http://${DevExternalIP}:8000"

}
else {

    Write-Host ""
    Write-Host "DEV:"
    Write-Host "External IP is not available yet."
}


Write-Host ""
Write-Host "========================================"
Write-Host " Startup completed successfully"
Write-Host "========================================"