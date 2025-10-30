# Step-by-Step Guide: Creating GCP Account and Service Account JSON Key for Terraform

## Step 1: Creating a New Account with $300 Credit

1. Navigate to **https://console.cloud.google.com** or **https://cloud.google.com/free**
2. Click on **"Get started for free"** or **"Try it free"**
3. Sign in with your Google account (or create a new one)
4. Fill in your account information:
   - Select your **country**
   - Choose **account type** (Individual or Business)
   - Enter your **name and address**
   - Add your **payment method** (credit/debit card)
   - **Note:** You won't be charged during the free trial
5. Accept the terms of service
6. Click **"Start my free trial"**

![](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/01.png)

**Result:** You now have a GCP account with $300 in free credits valid for 90 days.

------

## Step 2: Enable API and Services - Select Compute Engine API

### Step 2.1: Navigate to APIs & Services

1. Open the **navigation menu** (☰ hamburger icon in the top-left)
2. Click on **"APIs & Services"**
3. Select **"Library"** or **"Enable APIs and Services"**

![image-20251012175320176](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/02.png)

### Step 2.2: Search for Compute Engine API

1. In the search bar, type **"Compute Engine API"**
2. Click on **"Compute Engine API"** from the results

![image-20251012175335477](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/03.png)

### Step 2.3: Enable the API

1. Click the **"ENABLE"** button
2. Wait for the API to be enabled (takes a few seconds)

![image-20251012175246748](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/04.png)

**Result:** The Compute Engine API is now enabled for your project.

------

## Step 3: IAM and Admin > Service Accounts

### Step 3.1: Navigate to Service Accounts

1. Open the **navigation menu** (☰)
2. Go to **"IAM & Admin"**
3. Click on **"Service Accounts"**



### Step 3.2: Create a New Service Account

1. Click **"+ CREATE SERVICE ACCOUNT"** at the top
2. Enter **service account name** (e.g., "terraform-service-account")
3. Add an optional **description** (e.g., "Service account for Terraform")
4. Click **"CREATE AND CONTINUE"**

![image-20251012175451940](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/05.png)

------

## Step 4: Choose Permissions

1. In the **"Grant this service account access to project"** section
2. Click the **"Select a role"** dropdown
3. Search for and select the appropriate role:
   - **Editor** (for development/testing)
   - Or specific roles like **Compute Admin**, **Storage Admin**, etc.
4. Click **"CONTINUE"**
5. Skip the optional "Grant users access" section
6. Click **"DONE"**

**Result:** Your service account is now created with the specified permissions.

![Screenshot 2025-10-12 at 6.05.04 PM](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/06.png)

------

## Step 5: From Actions, Choose Manage Keys

1. Locate your newly created service account in the list
2. Click the **three vertical dots (⋮)** under the **"Actions"** column
3. Select **"Manage keys"** from the dropdown menu

![image-20251012175705109](/Users/lotfinejad/terraform_projects/terraform-gcp-guide/01-setup/images/07.png)

------

## Step 6: From Add Keys, Choose Create New Key and Choose JSON

1. On the Keys page, click **"ADD KEY"**
2. Select **"Create new key"** from the dropdown
3. In the dialog box:
   - Select **"JSON"** as the key type
   - Click **"CREATE"**

**Result:** The JSON key file will automatically download to your computer.

------

## Step 7: Save the Key in a Secure Place

### Important Security Steps:

1. **Locate the downloaded file** (named something like `project-id-123abc.json`)

2. **Move it to a secure location:**

   - **Linux/Mac:** `~/.gcp/` or `~/.config/gcloud/`
   - **Windows:** `C:\Users\YourName\.gcp\`

3. **Rename it** (optional) to something like `terraform-key.json`

4. **Set proper permissions** (Linux/Mac only):

   ```bash
   chmod 600 ~/.gcp/terraform-key.json
   ```

5. **Never commit to version control** - Add to `.gitignore`:

   ```
   *.json
   .gcp/
   *credentials*.json
   ```

### Using the Key with Terraform:

Create a `provider.tf` file:

```hcl
provider "google" {
  credentials = file("~/.gcp/terraform-key.json")
  project     = "your-project-id"
  region      = "us-central1"
}
```

Or use environment variables (recommended):

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
```

------

## Summary

You have successfully:

- ✅ Created a GCP account with $300 free credit
- ✅ Enabled the Compute Engine API
- ✅ Created a service account with appropriate permissions
- ✅ Generated a JSON key file
- ✅ Saved the key securely

**Your GCP service account JSON key is now ready to use with Terraform!**