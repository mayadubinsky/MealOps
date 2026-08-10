# Stop the script when a PowerShell command throws an error.
$ErrorActionPreference = "Stop"


# ============================================================
# Paths
# ============================================================

# $PSScriptRoot is:
# C:\Users\maya\MealOps\scripts
#
# Go one directory up to get the MealOps project root.
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Terraform infrastructure directory.
$TerraformDir = Join-Path $ProjectRoot "terraform\infra"


# ============================================================
# Helper functions
# ============================================================

function Write-Step {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "==> $Message"
}


# ============================================================
# Start
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "        MealOps Environment Stop"
Write-Host "========================================"
Write-Host ""

Write-Host "Terraform directory:"
Write-Host $TerraformDir
Write-Host ""


# ============================================================
# Validate Terraform directory
# ============================================================

# Make sure the expected Terraform directory exists.
if (-not (Test-Path $TerraformDir)) {
    throw "Terraform directory does not exist: $TerraformDir"
}


# Make sure this actually looks like a Terraform directory.
#
# This protects us from accidentally running terraform destroy
# from the wrong directory.
$TerraformFiles = Get-ChildItem `
    -Path $TerraformDir `
    -Filter "*.tf" `
    -File

if (-not $TerraformFiles) {
    throw "No Terraform files found in: $TerraformDir"
}


# ============================================================
# Move to Terraform infrastructure directory
# ============================================================

Write-Step "Opening Terraform infrastructure directory..."

Push-Location $TerraformDir


# ============================================================
# Initialize Terraform
# ============================================================

Write-Step "Initializing Terraform..."

# Makes sure Terraform has the correct backend and providers
# before we try to destroy the infrastructure.
terraform init

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform init failed."
}

Write-Host "Terraform initialized - OK"


# ============================================================
# Show what Terraform is going to destroy
# ============================================================

Write-Step "Creating Terraform destroy plan..."

# Create a destroy plan first instead of immediately destroying
# the infrastructure.
#
# The plan is saved temporarily as mealops-destroy.tfplan.
terraform plan `
    -destroy `
    -out="mealops-destroy.tfplan"

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    throw "terraform destroy plan failed."
}


# ============================================================
# Confirmation
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "WARNING"
Write-Host "========================================"
Write-Host ""
Write-Host "The resources shown above will be destroyed."
Write-Host ""

# Require an explicit confirmation before deleting anything.
$Confirmation = Read-Host "Type DESTROY to continue"

if ($Confirmation -cne "DESTROY") {

    Write-Host ""
    Write-Host "Destroy cancelled."

    # Delete the temporary Terraform plan.
    Remove-Item "mealops-destroy.tfplan" -ErrorAction SilentlyContinue

    Pop-Location
    exit 0
}


# ============================================================
# Destroy infrastructure
# ============================================================

Write-Step "Destroying MealOps Azure infrastructure..."

# Apply the destroy plan we reviewed above.
#
# Because we're applying an already-created plan, Terraform
# doesn't need another confirmation.
terraform apply "mealops-destroy.tfplan"

if ($LASTEXITCODE -ne 0) {

    # Remove the temporary plan if possible.
    Remove-Item "mealops-destroy.tfplan" -ErrorAction SilentlyContinue

    Pop-Location

    throw "Terraform destroy failed."
}


# ============================================================
# Cleanup
# ============================================================

# Remove the temporary destroy plan.
Remove-Item "mealops-destroy.tfplan" -ErrorAction SilentlyContinue

# Return to the directory from which the script was started.
Pop-Location


# ============================================================
# Finished
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "     MealOps environment destroyed"
Write-Host "========================================"
Write-Host ""
Write-Host "Azure infrastructure managed by"
Write-Host "terraform/infra has been destroyed."
Write-Host ""
Write-Host "Your Terraform backend/bootstrap"
Write-Host "infrastructure was NOT destroyed."
Write-Host ""
Write-Host "Stop completed successfully."
Write-Host "========================================"