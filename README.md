# Windows 11 Azure Image with Packer

This Packer configuration builds a custom Windows 11 Pro image on Azure.

## Prerequisites

- Azure CLI installed and authenticated
- Packer installed (v1.14.3+)
- Active Azure subscription

## What's Included

The image includes:
- Windows 11 Pro (23H2)
- Latest Windows Updates
- Chocolatey package manager
- Google Chrome
- 7-Zip
- Notepad++

## Files

- `windows11-azure.pkr.hcl` - Main Packer template
- `variables.pkrvars.hcl` - Variable definitions
- `manifest.json` - Build output manifest (generated after build)

## Configuration

The default configuration:
- **Resource Group**: rg-packer-images (will be created if it doesn't exist)
- **Location**: eastus
- **VM Size**: Standard_D2s_v3
- **Image Name**: Windows11-Pro-YYYY-MM-DD-hhmm

## Usage

1. **Initialize Packer** (download required plugins):
   ```bash
   packer init .
   ```

2. **Validate the template**:
   ```bash
   packer validate -var-file="variables.pkrvars.hcl" windows11-azure.pkr.hcl
   ```

3. **Build the image**:
   ```bash
   packer build -var-file="variables.pkrvars.hcl" windows11-azure.pkr.hcl
   ```

## Customization

Edit `variables.pkrvars.hcl` to customize:
- Azure region/location
- VM size
- Resource group name
- Image name

Edit `windows11-azure.pkr.hcl` to:
- Add/remove software installations
- Modify Windows Update settings
- Add custom provisioning scripts

## Build Time

Expect the build to take 45-90 minutes depending on:
- Windows Updates available
- Software installations
- Azure region performance
- VM size selected

## Output

After successful build, you'll have:
- A managed image in your Azure subscription
- `manifest.json` file with image details
- The image will be available to create VMs from Azure Portal or CLI

## Clean Up

To delete the image after testing:
```bash
az image delete --name <image-name> --resource-group rg-packer-images
```
