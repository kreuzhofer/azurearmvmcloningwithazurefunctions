<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="AzureVMGenerator._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="jumbotron">
       
        <p><asp:TextBox ID="nameTextBox" Text="Name" runat="server"></asp:TextBox></p>
        <p><asp:TextBox ID="eMailTextBox" Text="eMail Address" runat="server"></asp:TextBox></p>
        <p><asp:TextBox ID="bodyTextBox" Text="Your Message..." runat="server"></asp:TextBox></p>

        <asp:Button ID="SendButton" Onclick="SendButton_Click" runat="server" Text="Send" class="btn btn-primary btn-lg" />
        <p><asp:Label ID="messageLabel" Text="" runat="server" ></asp:Label></p>
        
    </div>

    <div class="row">
        <div class="col-md-4">
            
        </div>
        
    </div>

</asp:Content>
