using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Net.Mail;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading.Tasks;
using System.Diagnostics;
using System.IO;
using Microsoft.Azure;
using Microsoft.WindowsAzure.Storage;

namespace AzureVMGenerator
{
    public partial class _Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }
        protected void SendButton_Click(Object sender, EventArgs e)
        {
            //Create Variables
            string nameString = nameTextBox.Text;
            string eMailString = eMailTextBox.Text;
            string bodyString = bodyTextBox.Text;
            messageLabel.Text += "Your request was sent successfully. We are creating your trial for you now...<br/>";
			nameTextBox.Enabled = false;
			eMailTextBox.Enabled = false;
			bodyTextBox.Enabled = false;
			SendButton.Enabled = false;
            RunAzureFunction(nameString, eMailString, bodyString);
        }

		public void RunAzureFunction(string customerName, string eMailToAddr, string bodyText)
		{
			//Generate random 8 digit string
			var pChars = "abcdefghijklmnopqrstuvwxyz";
			var chars = new char[8];
			Random randC = new Random();

			for (int i = 0; i < chars.Length; i++)
			{
				chars[i] = pChars[randC.Next(chars.Length)];
			}

			string randGenString = new String(chars);

			try
			{
				// generate json message for powershell script
				var messageJson = $@"
{{
	""deploymentName"": ""{randGenString}"",
	""emailTOAddress"" : ""{eMailToAddr}"",
    ""emailCCAddress"" : ""daniel.kreuzhofer@microsoft.com"",
    ""emailBody"" : ""{bodyText}"",
    ""customerName"" : ""{customerName}""
}}
";

				var storageAccount = CloudStorageAccount.Parse(CloudConfigurationManager.GetSetting("AzureStorageConnectionString"));
				var queueClient = storageAccount.CreateCloudQueueClient();
				var queue = queueClient.GetQueueReference("trial-powershell");
				queue.AddMessage(new Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage(messageJson));
            }
            catch (SmtpException e)
            {
                Console.Write("Error:" + e);
            }
        }
	}
}