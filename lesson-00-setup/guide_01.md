# Terraform Installation Guide for GCP Projects

## 1. Installing Terraform on Windows

Terraform is distributed as a single executable file. Installing it on Windows involves downloading the executable and setting up your system's `PATH` environment variable.

### Prerequisites

- A Windows 10 or later operating system
- Administrative privileges

### Step 1: Download Terraform

1. Open your web browser and navigate to the [Terraform download page](https://www.terraform.io/downloads.html).
2. Scroll down to the **Windows** section.
3. Click on the **"64-bit"** link to download the Terraform ZIP file. If you're running a 32-bit system (less common), download the **"32-bit"** version.

### Step 2: Extract the ZIP File

1. Locate the downloaded ZIP file in your **Downloads** folder.
2. Right-click the ZIP file and select **"Extract All..."**.
3. Choose a destination folder to extract the files. For simplicity, extract it to a folder named `terraform` in your `C:\` drive:
   - **Destination**: `C:\terraform`
4. Click **"Extract"**.

### Step 3: Add Terraform to System PATH

Adding Terraform to your system's `PATH` allows you to run the `terraform` command from any directory.

1. **Copy the Folder Path**:
   - Open **File Explorer** and navigate to `C:\terraform`.
   - Click on the address bar and copy the path `C:\terraform`.

2. **Open Environment Variables**:
   - Press `Windows Key + R`, type `sysdm.cpl`, and press **Enter** to open **System Properties**.
   - Go to the **"Advanced"** tab.
   - Click on **"Environment Variables..."** at the bottom.

3. **Edit the System PATH Variable**:
   - Under **"System variables"**, scroll to find the **"Path"** variable.
   - Select it and click **"Edit..."**.

4. **Add a New Entry**:
   - Click **"New"**.
   - Paste the folder path `C:\terraform` into the new line.
   - Click **"OK"** to close each dialog.

### Step 4: Verify the Installation

1. Open **Command Prompt**:

   - Press `Windows Key + R`, type `cmd`, and press **Enter**.

2. Run the following command:

   ```shell
   terraform -v
   ```

3. You should see output similar to:

   ```text
   Terraform v1.13.3
   ```

   This confirms that Terraform is installed and accessible from the command line.

---

## 2. Installing Terraform on macOS

On macOS, you can install Terraform using Homebrew, a popular package manager for macOS.

### macOS Prerequisites

- A macOS system running Mojave or later
- Administrative privileges
- Command Line Tools (CLT) for Xcode (usually pre-installed)

### Step 1: Install Homebrew (If Not Already Installed)

Homebrew simplifies software installation on macOS.

1. Open **Terminal**:

   - You can find it in **Applications** > **Utilities** > **Terminal**.

2. Install Homebrew by running:

   ```shell
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Follow the prompts:

   - You may need to enter your password.
   - The installation script will explain what it will do and pause before it does it.

4. Verify Homebrew Installation:

   ```shell
   brew --version
   ```

   You should see the version number displayed.

### Step 2: Install Terraform Using Homebrew

With Homebrew installed, installing Terraform is straightforward.

1. Run the following command in Terminal:

   ```shell
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```

   - The first command taps the HashiCorp Homebrew repository.
   - The second command installs Terraform.

2. **Verify the Installation**:

   ```shell
   terraform -v
   ```

   You should see output similar to:

   ```text
   Terraform v1.13.3
   ```

### Alternative Method: Manual Installation

If you prefer not to use Homebrew, you can install Terraform manually.

#### Download Terraform for Manual Installation

1. Navigate to the [Terraform download page](https://www.terraform.io/downloads.html).
2. Scroll to the **macOS** section.
3. Download the appropriate ZIP file for your system (most likely **"AMD64 (64-bit)"**).

#### Step 2: Extract and Move the Executable

1. Locate the downloaded ZIP file (usually in your **Downloads** folder).

2. Double-click the ZIP file to extract it.

3. Move the `terraform` executable to a directory included in your system `PATH`. A common location is `/usr/local/bin`.

   ```shell
   sudo mv ~/Downloads/terraform /usr/local/bin/
   ```

4. **Set the Executable Permission**:

   ```shell
   sudo chmod +x /usr/local/bin/terraform
   ```

#### Step 3: Verify the Installation

Run the following command:

```shell
terraform -v
```

---

## 3. Updating Terraform to the Latest Version

Terraform regularly releases updates with new features, bug fixes, and security improvements. It's important to keep your Terraform installation up to date.

### Checking Your Current Version

First, check your current Terraform version:

```shell
terraform -version
```

If you see output like this, your Terraform is out of date:

```text
Terraform v1.9.8
on darwin_arm64

Your version of Terraform is out of date! The latest version
is 1.13.3. You can update by downloading from https://www.terraform.io/downloads.html
```

### Updating Terraform on macOS

#### Method 1: Using Homebrew (Recommended)

If you installed Terraform using Homebrew, updating is simple:

```shell
brew update
brew upgrade hashicorp/tap/terraform
```

Verify the update:

```shell
terraform -version
```

#### Method 2: Manual Update

If you installed Terraform manually:

1. **Download the Latest Version**:

   - Visit the [Terraform download page](https://www.terraform.io/downloads.html)
   - Download the latest macOS version (for Apple Silicon: darwin_arm64)

2. **Replace the Existing Binary**:

   ```shell
   # Backup current version (optional)
   sudo mv /usr/local/bin/terraform /usr/local/bin/terraform.backup
   
   # Extract and move new version
   unzip ~/Downloads/terraform_1.13.3_darwin_arm64.zip
   sudo mv terraform /usr/local/bin/
   sudo chmod +x /usr/local/bin/terraform
   ```

3. **Verify the Update**:

   ```shell
   terraform -version
   ```

### Updating Terraform on Windows

The easiest way to update Terraform on Windows is using **Chocolatey**, the most popular package manager for Windows.

#### Step 1: Install Chocolatey (If Not Already Installed)

1. **Open PowerShell as Administrator**:

   - Right-click the **Start** button
   - Select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**

2. **Run the Chocolatey installation command**:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

3. **Close and reopen PowerShell** to refresh your environment

4. **Verify Chocolatey installation**:

   ```shell
   choco --version
   ```

#### Step 2: Update Terraform

Once Chocolatey is installed, updating Terraform is simple:

```shell
choco upgrade terraform
```

If Terraform isn't installed yet:

```shell
choco install terraform
```

#### Step 3: Verify the Update

```shell
terraform -version
```

You should see the latest version installed.

**Note**: Chocolatey will automatically handle the PATH configuration and can manage updates for all your development tools in one place.

### Important Update Considerations

⚠️ **Before updating in production environments:**

1. **Check Compatibility**: Review the [Terraform changelog](https://github.com/hashicorp/terraform/blob/main/CHANGELOG.md) for breaking changes
2. **Test in Development**: Update your development environment first
3. **State File Compatibility**: Ensure your state files are compatible with the new version
4. **Provider Compatibility**: Check that your providers support the new Terraform version

---

## 4. Installing and Configuring Google Cloud SDK (gcloud CLI)

The Google Cloud SDK (gcloud CLI) is essential for authenticating with GCP and managing cloud resources. While Terraform can use service account JSON keys, the gcloud CLI provides additional authentication methods and is invaluable for testing and troubleshooting your GCP infrastructure.

### Why Install gcloud CLI?

- **Authentication**: Provides Application Default Credentials (ADC) for Terraform
- **Project Management**: Easy project switching and configuration
- **Testing**: Verify GCP resources and permissions before running Terraform
- **Troubleshooting**: Debug and inspect your GCP infrastructure
- **Integration**: Works seamlessly with Terraform and other GCP tools

### Installing gcloud CLI on Windows

#### Step 1: Download the Installer

1. Visit the [Google Cloud SDK download page](https://cloud.google.com/sdk/docs/install)
2. Download the **Google Cloud SDK installer** for Windows
3. Run the downloaded installer (`.exe` file)

#### Step 2: Run the Installation

1. Follow the installation wizard prompts
2. When asked, check the following options:
   - ☑ **Install Google Cloud SDK**
   - ☑ **Start Google Cloud SDK Shell**
   - ☑ **Run 'gcloud init'**
3. Complete the installation

#### Step 3: Verify Installation

Open **Command Prompt** or **PowerShell** and run:

```shell
gcloud --version
```

You should see output showing the gcloud version and components.

### Installing gcloud CLI on macOS

#### Method 1: Using Homebrew (Recommended)

```shell
# Install gcloud CLI
brew install --cask google-cloud-sdk

# Verify installation
gcloud --version
```

#### Method 2: Interactive Installer

1. Download the installer:

```shell
# For macOS (Apple Silicon - M1/M2/M3)
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz

# For macOS (Intel)
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz
```

2. Extract and install:

```shell
# Extract the archive
tar -xzf google-cloud-cli-darwin-arm.tar.gz

# Run the install script
./google-cloud-sdk/install.sh

# Initialize your configuration (optional at this point)
./google-cloud-sdk/bin/gcloud init
```

3. Update your shell configuration:

```shell
# Add to PATH (the installer will prompt you)
source ~/.zshrc  # or source ~/.bash_profile
```

4. Verify installation:

```shell
gcloud --version
```

### Initializing gcloud CLI

After installation, initialize the gcloud CLI to configure your settings:

```shell
gcloud init
```

This will:

1. Open a browser for authentication
2. Prompt you to select or create a GCP project
3. Configure default compute region and zone

**Follow the prompts:**

```text
Welcome! This command will take you through the configuration of gcloud.

Pick configuration to use:
 [1] Re-initialize this configuration [default] with new settings
 [2] Create a new configuration
Please enter your numeric choice: 1

Choose the account you would like to use to perform operations:
 [1] your-email@example.com
 [2] Log in with a new account
Please enter your numeric choice: 1

Pick cloud project to use:
 [1] your-project-id
 [2] Create a new project
Please enter numeric choice or project ID: 1

Do you want to configure a default Compute Region and Zone? (Y/n)? Y
```

### Authenticating for Terraform

For Terraform to authenticate with GCP using your gcloud credentials, run:

```shell
gcloud auth application-default login
```

This command:

- Opens your browser for authentication
- Creates Application Default Credentials (ADC)
- Stores credentials that Terraform can automatically use

**Where credentials are stored:**

- **Windows**: `%APPDATA%\gcloud\application_default_credentials.json`
- **macOS/Linux**: `~/.config/gcloud/application_default_credentials.json`

### Essential gcloud Commands for GCP Development

#### Check Authentication Status

```shell
# List authenticated accounts
gcloud auth list

# Show current configuration
gcloud config list
```

#### Project Management

```shell
# List all projects
gcloud projects list

# Set default project
gcloud config set project PROJECT_ID

# Get current project
gcloud config get-value project
```

#### Set Default Region and Zone

```shell
# Set default region
gcloud config set compute/region us-central1

# Set default zone
gcloud config set compute/zone us-central1-a

# View current settings
gcloud config list
```

#### Service Account Management

```shell
# List service accounts
gcloud iam service-accounts list

# Create a service account
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account"

# Grant roles to service account
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:terraform-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"
```

#### Enable APIs

```shell
# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Cloud Storage API
gcloud services enable storage.googleapis.com

# List enabled services
gcloud services list --enabled
```

### Configuring Terraform to Use gcloud Credentials

#### Method 1: Application Default Credentials (Recommended for Development)

After running `gcloud auth application-default login`, Terraform will automatically use these credentials. No additional configuration needed in your Terraform code:

```hcl
# provider.tf
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}
```

#### Method 2: Service Account Key File

If using a service account JSON key:

```hcl
# provider.tf
provider "google" {
  credentials = file("~/.gcp/terraform-key.json")
  project     = "your-project-id"
  region      = "us-central1"
}
```

#### Method 3: Environment Variables

```shell
# Set the credentials file path
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"

# Set the project ID
export GOOGLE_PROJECT="your-project-id"

# Set the region
export GOOGLE_REGION="us-central1"
```

### Verifying Your Setup

Test your gcloud and GCP connectivity:

```shell
# Verify authentication
gcloud auth list

# Check current project
gcloud config get-value project

# Test API access (list compute instances)
gcloud compute instances list

# Check enabled APIs
gcloud services list --enabled
```

### Updating gcloud CLI

Keep your gcloud CLI up to date:

```shell
# Update all components
gcloud components update

# Check for available updates
gcloud components list
```

### Common gcloud CLI Issues and Solutions

#### Issue: Command not found

**Solution:**

- **Windows**: Restart your terminal or run the Cloud SDK Shell
- **macOS**: Add gcloud to PATH or run `source ~/.zshrc`

#### Issue: Authentication errors

**Solution:**

```shell
# Re-authenticate
gcloud auth login

# Re-initialize application default credentials
gcloud auth application-default login

# Verify credentials
gcloud auth list
```

#### Issue: Wrong project selected

**Solution:**

```shell
# List available projects
gcloud projects list

# Switch to correct project
gcloud config set project YOUR_PROJECT_ID
```

---

## 5. Setting Up Visual Studio Code for Terraform Development

Visual Studio Code (VS Code) is the recommended code editor for Terraform development. It provides excellent support for Terraform with syntax highlighting, IntelliSense, and powerful extensions that streamline your infrastructure-as-code workflow.

### Step 1: Install Visual Studio Code

If you don't have VS Code installed:

1. Visit the [Visual Studio Code download page](https://code.visualstudio.com/)
2. Download the appropriate version for your operating system
3. Follow the installation instructions for your platform

### Step 2: Install Essential Terraform Extensions

After installing VS Code, you'll want to install these essential extensions for Terraform development:

#### 1. HashiCorp Terraform Extension (Recommended)

This is the official Terraform extension from HashiCorp.

**Installation:**

1. Open VS Code
2. Click on the Extensions icon in the sidebar (or press `Ctrl+Shift+X` / `Cmd+Shift+X`)
3. Search for "HashiCorp Terraform"
4. Click **Install** on the extension by HashiCorp

**Features:**

- Syntax highlighting and error highlighting
- IntelliSense and auto-completion
- Code formatting with `terraform fmt`
- Integration with Terraform CLI commands
- Validation and linting
- Hover documentation
- Go to definition and references

#### 2. Terraform Autocomplete Extension

**Installation:**

1. In VS Code Extensions marketplace
2. Search for "Terraform"
3. Install "Terraform" by Anton Kulikov

**Features:**

- Enhanced autocomplete for Terraform configurations
- Resource and data source suggestions
- Variable and output completion

#### 3. Azure Terraform Extension (Optional for Azure resources)

If you plan to work with Azure resources alongside GCP:

**Installation:**

1. Search for "Azure Terraform" in Extensions
2. Install the extension by Microsoft


## 6. Next Steps

With Terraform, gcloud CLI, and VS Code all configured, you're ready to start defining and deploying infrastructure on Google Cloud Platform (GCP). Here are your next steps:

- **Authenticate with GCP**: Ensure you've run `gcloud auth application-default login` for Terraform authentication
- **Create a GCP Project**: Use the GCP Console or `gcloud projects create` to set up your project
- **Enable Required APIs**: Enable Compute Engine, Cloud Storage, and other APIs you'll need
- **Create Your First Terraform Project**: Start with simple GCP resources like Cloud Storage buckets or Compute Engine instances
- **Learn Terraform Best Practices**: Understand state management, modules, and workspace organization
- **Explore GCP Services**: Familiarize yourself with GCP's offerings and how to provision them with Terraform

---

## 7. Troubleshooting

### Terraform Installation Issues

- **Command Not Found**: If running `terraform -v` returns a "command not found" error:
  - Ensure that the Terraform executable is in your system's `PATH`.
  - On Windows, double-check the environment variable settings.
  - On macOS, make sure the installation completed without errors.

- **Permission Issues**:
  - On macOS and Linux, you may need to use `sudo` when moving files to system directories.
  - Ensure you have administrative privileges during installation.

### VS Code Extension Issues

- **Extension Not Working**: If Terraform extensions aren't providing features:
  - Restart VS Code after installing extensions
  - Check that files have the correct `.tf` extension
  - Verify Terraform is installed and accessible from terminal
  - Check VS Code's Output panel for extension error messages

- **Formatting Not Working**: If auto-formatting isn't working:
  - Ensure the HashiCorp Terraform extension is set as the default formatter
  - Check that `terraform fmt` command works in terminal
  - Verify the settings configuration is applied correctly

- **IntelliSense Issues**: If auto-completion isn't working:
  - Make sure you're working in a valid Terraform project directory
  - Check that the extension can access Terraform CLI
  - Try reloading the VS Code window (`Ctrl+Shift+P` → "Developer: Reload Window")

---

## 8. Conclusion

You've successfully set up a complete development environment for Terraform on GCP! You now have:

- **Terraform installed** and up to date
- **Google Cloud SDK (gcloud CLI)** configured and authenticated
- **Visual Studio Code** with essential Terraform extensions
- **Complete toolchain** for GCP infrastructure automation

This powerful combination provides you with an optimal development environment for automating your GCP infrastructure deployments. Terraform's declarative approach, combined with gcloud CLI's management capabilities and VS Code's intelligent features, will help you manage resources efficiently and consistently across your Google Cloud environments.