#### Azure ARM (Azure Resource Manager) virtual machine cloning with Azure Functions
With this project you will be able to set up a simple web portal, where people can "order" new virtual machines that get cloned from a master vm image (optionally with attached data disks)


#### Prerequisites
If you haven't already done so, set up a Microsoft Azure account at https://portal.azure.com. 


###### Create a Service Principal
//// Review this section; Links are Ok ////

Create a Service Principal. 
- [You can find further information on setting up Service Principals here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal)
- [You can find further information on authenticating against Service Principals here](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal)

###### Create an Azure Function
Create an Azure Function. To do so, log into https://portal.azure.com, click on "New" in the left hand side column, then type in "Function App". Select "Function App" published by Microsoft, then click "Create". 

###### Create the template VM that you want to clone later
Create an Azure Virtual Machine. To do so, log into https://portal.azure.com, click on "New" in the left hand side column, then select "Compute". Select the OS of your choice, and enter the requested information. Create the Virtual Machine. 


#### Installation
Open the .sln file included in this repository. 
In the right hand side column of Visual Studio, select "Connected Services". A new tab opens. Then click on Publish. 
If you have an existing Microsoft Azure App Service that you'd like to use, select "Select Existing". 
Otherwise, select "Create New". In either case, click on "Publish". 

Set a Web App Name, Select a Subscription, a Resource Group, and an App Service Plan. 
You may create a new Resource Group and a new App Service Plan, if you haven't already done so. 
Click "Create". Visual Studio will automatically deploy your WebApp. 


#### Deployment using alternative techniques
This sample uses Visual Studio to deploy the WebApp. You can find further instructions on how to deploy WebApps by other means [here](https://docs.microsoft.com/en-us/azure/app-service-web/web-sites-deploy). 