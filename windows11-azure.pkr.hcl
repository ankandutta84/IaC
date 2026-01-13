packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
    windows-update = {
      version = ">= 0.16.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "subscription_id" {
  type    = string
  default = "e0412ce6-7a62-43b5-8d9f-96f1b30c0105"
}

variable "tenant_id" {
  type    = string
  default = "b6a9e928-5b1b-4256-8992-42e9b0e7b232"
}

variable "resource_group_name" {
  type    = string
  default = "rg-packer-images"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "image_name" {
  type    = string
  default = "Windows11-Pro"
}

source "azure-arm" "windows11" {
  # Authentication
  use_azure_cli_auth = true
  subscription_id    = var.subscription_id
  tenant_id          = var.tenant_id

  # Resource Group - Packer will create a temporary RG if not specified
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = "${var.image_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Location
  location = var.location

  # OS Details - Windows 11 Pro
  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "windows-11"
  image_sku       = "win11-23h2-pro"

  # VM Configuration
  vm_size = var.vm_size

  # Communicator - WinRM for Windows
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "30m"
  winrm_username = "packer"

  # Azure VM configuration
  async_resourcegroup_delete = true
}

build {
  sources = ["source.azure-arm.windows11"]

  # Windows Updates
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "include:$true"
    ]
    update_limit = 25
  }

  # Install Chocolatey
  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    ]
  }

  # Install common tools (optional - customize as needed)
  provisioner "powershell" {
    inline = [
      "choco install googlechrome -y",
      "choco install 7zip -y",
      "choco install notepadplusplus -y"
    ]
  }

  # Run Windows Sysprep
  provisioner "powershell" {
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while ($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select-Object ImageState; Write-Output $imageState.ImageState; if($imageState.ImageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE' -or $imageState.ImageState -eq 'IMAGE_STATE_COMPLETE') { break } Start-Sleep -s 10 }"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
