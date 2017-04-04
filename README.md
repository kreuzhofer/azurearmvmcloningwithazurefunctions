#### Azure ARM (Azure Resource Manager) virtual machine cloning with Azure Functions
With this project you will be able to set up a simple web portal, where people can "order" new virtual machines that get cloned from a master vm image (optionally with attached data disks)


#### Overview
![Overview](https://github.com/kreuzhofer/azurearmvmcloningwithazurefunctions/blob/master/docs/VmCloningProcessOverview.png)


#### Contributions
[kreuzhofer](https://github.com/kreuzhofer), initial project setup, powershell scripting

thanks to [horrion](https://github.com/horrion) for creating the web-portal, documentation and testing


#### Prerequisites
If you haven't already done so, set up a Microsoft Azure account at https://portal.azure.com. 


###### Create a Service Principal
Create a Service Principal. 

[You can find further information on setting up Service Principals here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal)

[You can find further information on authenticating against Service Principals here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal)

###### Create an Azure Function
Create an Azure Function. To do so, log into https://portal.azure.com, click on "New" in the left hand side column, then type in "Function App". Select "Function App" published by Microsoft, then click "Create". 

Select PowerShell in the language drop down menu. Then select "Queue trigger" as a trigger. Make sure to use the same storage account as the WebApp. 

Note: The Azure Function and WebApp have to use the same Consumption Plan. Do not set up the function under "Shared Consumption".

Copy the contents of the Powershell Script "NewARMVmFromVHD_RunAsAzureFunction.ps1" into the Azure Function. It is located in "src\AzureVMGenerator\PowerShell"

###### Create the template VM that you want to clone later
Create an Azure Virtual Machine. To do so, log into https://portal.azure.com, click on "New" in the left hand side column, then select "Compute". Select the OS of your choice, and enter the requested information. Create the Virtual Machine. 

Access the VM by your method of choice. Set it up, install software of your choice.

Caution: keep in mind that all changes made to the default state of the VM will be reflected in every cloned Virtual Machine. This includes saved passwords. 

When you're done, stop the VM through the [Azure Portal](https://portal.azure.com). If the VM is still running, you won't be able to clone it. 

#### Installation
Open the .sln file included in this repository. 
In the right hand side column of Visual Studio, select "Connected Services". A new tab opens. Then click on Publish. 
If you have an existing Microsoft Azure App Service that you'd like to use, select "Select Existing". 
Otherwise, select "Create New". In either case, click on "Publish". 

Set a Web App Name, Select a Subscription, a Resource Group, and an App Service Plan. 
You may create a new Resource Group and a new App Service Plan, if you haven't already done so. 
Click "Create". Visual Studio will automatically deploy your WebApp. 

#### WebApp Configuration
Copy an access key and paste it into your WebApp's configuration. 
Find your storage account's connection string under <your-storage-account-name> -> Access Keys. You can find the WebApp's configuration under <your-WebApp-Name> -> Application settings. Paste it into the Value textbox under "App settings", then save the configuration. 

#### Deployment using alternative techniques
This sample uses Visual Studio to deploy the WebApp. You can find further instructions on how to deploy WebApps by other means [here](https://docs.microsoft.com/en-us/azure/app-service-web/web-sites-deploy). 


#### Best Practices
Use a single one resource group for the entire project. 

Make sure to keep all resources in the same location. 