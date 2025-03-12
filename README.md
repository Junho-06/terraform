# Install Chocolatey
1. Run a **Powershell** as **Administrative**
2. Run command `Get-ExecutionPolicy`
    1. If it returns `Restricted`, run command `Set-ExecutionPolicy AllSigned` and Enter `Y`
    2. If it not returns `Restricted`, pass this step
3. Now Run install command
    ```
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    ```
4. If you enter `choco`, can check **Chocolatey** version


# Install Terraform with Chocolatey
Install Command
```
choco install terraform
```
Terraform version check
```
terraform version
```


# How to Use This Template
1. Select a Module what you want ( ex: VPC, RDS, S3 ... )
2. Change variable value in `variables.tf`
3. Terraform module initializing
    ```
    terraform init
    ```
4. Terraform apply a module
    ```
    terraform apply --auto-approve
    ```



> ## ${\textsf{\color{Red}🚧 Warning 🚧}}$
> **${\textsf{\color{White}You Should check your Region}}$**  
> ${\textsf{\color{White}(ex: aws configure, variables.tf file)}}$