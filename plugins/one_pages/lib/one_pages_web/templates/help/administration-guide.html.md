*   [Introduction](#introduction)
*   [Infinity One Package](#package)
*   [Installation Wizard](#wizard)
*   [First time Login](#login)
*   [Adding Users](#users)
*   [Setting up WebRTC](#webrtc)
*   [Useful Tips](#tips)
*   [Known Issues](#issues)

# <a id="introduction"></a>Introduction

Infinity One is E-MetroTel's framework for the next generation of unified communications clients, providing team collaboration tools and applications for businesses of all sizes. The vision is to provide a set of modern features and tools for the evolving company integrated into one extensible frame work that includes:

*   An enterprise class web-based telephone that is available anywhere your employees have an Internet connection
*   Share important messaging conversations that would normally be hidden in point to point conversations with tools like SMS and Skype
*   Choose the most effective method of communication by checking their on-line or on-the-phone presence
*   Upload, search and download documents, images, videos, and audio files in chat rooms and share with the rest of your team
*   Start private conversations with direct messaging
*   Pin important messages for quick access for everyone
*   Star important messages for your quick reference
*   Track popularity of messages with message reactions and see who reacted
*   Never miss an important message with an advanced notification framework that provides audible, desktop, SMS, and email notifications. Control the noise by customizing the notifications on a room by room basis.
*   Highly configurable authorization policies including custom permissions and roles
*   Highly configurable with embedded, permissions-based administration screen
*   Available on all UCx platforms and E-MetroTel's cloud hosted service

And the best part is that the data is safe with encrypted connections between your browser and the server. All the data is stored on your own server, not on someone else's cloud.

# <a id="package"></a>Infinity One Package

The Infinity One package (infinity_one) is incompatible with the WebRTC package (mscs). If you have the mscs package already installed from Release 5, please uninstall mscs first before installing the infinity_one package.

The Infinity One application is installed on the UCx Server. First you have to install the **infinity_one** package:

1.  Login to the UCx Web-based Configuration Utility
2.  From the **System **tab, select **Updates**
3.  From the left side column, select **Packages**
4.  Click on **Show Filter**
5.  Under **Status **pull-down, select **All**
6.  In the **Name **field, enter **infinity_one**
7.  Click on the **Install **link to install the **infinity_one** package​

# <a id="wizard"></a>Installation Wizard

To access Infinity One from a web broswer, enter the IP address or hostname of the UCx Server followed by ' **:4021** '.
For example: http://192.168.1.200:4021

The application does not provision any default user when installed for security reasons. Instead, the first time you visit the site in your browser, you will be taken to an installation wizard.

#### Step 1 - Site URL / Host Name

The first page of the wizard allows your to change the host name / IP address that users will use to access the system.
![](/images/infinityone-install-1.png)

The field will be prepopulated with the IP/host name that you used to get to the wizard. It this is the same IP/Host that you will use, keep the default. 
However, if your are accessing the application for the first time from an internal IP that users will not normally use, then enter a different value here. The value should be the address used to create links in the outgoing email for invitations,  registrations, confirmations, and password resets. 

#### Step 2 - Administrator Account

The administration account you complete here does not require confirmation. So, once you have submitted the wizard, you can log in right away using the username and password configured here. 

![](/images/infinityone-install-2.png)

#### Step 3 - Default Channel

You will also be able to change the name of the first channel (room). The default is “general”. Keep it or change it. 
![](/images/infinityone-install-3.png)

#### Step 4 - Sending Email Settings

Infinity One uses the email server built into the UCx. You can change the name and email address that the emailer will use in the **From** field of the outgoing emails.
![](/images/infinityone-install-4.png)

#### Step 5 - Summary of Your Input

Review the information and click on the **SUBMIT** button to complete the installation.

![](/images/infinityone-install-5.png)

#### Step 6 - Complete

You can now click on the **Login Here** link to access the Infinity One application.
![](/images/infinityone-install-6.png)

# <a id="login"></a>First Time Login

Login using the administrator account that was created via the installation wizard.
![](/images/infinityone-login-1.png)

After logging in for the first time, restart the server as per instructions from the installation wizard. To restart the application:

1.  Click on the account box (top left where your username and avatar is shown)
    ![](/images/infinityone-login-2.png)
2.  Select: **Administration** -\> **General**
    ![](/images/infinityone-login-3.png)
3.  Click **RESTART THE SERVER** button
    ![](/images/infinityone-login-4.png)

If you selected the **Remember Me?** box on the login page, you should automatically be taken back into the application after it restarts (about a minute or so).

# <a id="users"></a>Adding Users

There are three methods to add users.

#### Method 1: Self Registration

Send the Infinity One URL to all users. (For example: http://192.168.1.200:4021)
The URL will take users to the login page. Users can click on the _**Register a new account **_link on the login page to register themselves.

#### Method 2: By Invitation

Login using the administrator account.
Under **Administration** -\> **Users**, you will find a paper airplane icon on the top right corner of the screen.
![](/images/UCC-client-3.png)

Clicking the icon will take you to a page where you can enter a list of email addresses.
![](/images/UCC-client-4.png)
The system will send out an invitation to each email with a link to register. The link will take them to the registration page.
After registration is complete, the user will receive a confirmation email that must be confirmed by clicking the confirmation link.

Future Enhancements:

*   Capability to disable the confirmation email option
*   Capability to disable the self registration feature

Remind users to check their spam and junk folders, very often these confirmation emails are filtered by the email servers.

#### Method 3: Add User

Login using the administrator account.
Under **Administration** -> **Users**, you will find a plus icon on the top right corner of the screen.
Clicking the icon will open up a form for adding the user.
![](/images/UCC-client-5.png)

This third method allows you to set the confirmed status and send a welcome email. However, the administrator will need to enter a password (or generate a random password) and communicate the password to the user separately.
The advantage of this approach is that you do not have to worry about people finding the invitation and confirmation emails in there spam folder.

It is recommended to setup one additional user as an administrator. This is your backup administrator in case you forget the administrator password and cannot recover it.

# <a id="webrtc"></a>Setting Up WebRTC

To allow users to have a WebRTC phone, the administrator must first create WebRTC extensions for each of the users on the UCx Server. (Nortel extensions with Device Type = WebRTC)
Then each user can associate their own WebRTC extension to their Infinity One account.

1.  User logs in to Infinity One
2.  Click on the Account Box (top left corner)
3.  Select **My Account** -\> **Phone**
    ![](/images/UCC-client-6.png)
4.  Switch on the **Enable WebRTC** toggle
5.  Enter the user's WebRTC extension number
6.  Choose the appropriate Label
7.  Click on **CREATE PHONE NUMBER** button
    ![](/images/UCC-client-7.png)

# <a id="tips"></a>Useful Tips

*   You can create new roles or change permissions to the various roles under **Administration** -\> **Permissions**
    ![](/images/UCC-client-8.png)
*   From the permissions page, you can click the top of the admin column and a new page will be presented where you can search for users and add them to the role.
    ![](/images/UCC-client-9.png)
*   The legacy WebRTC softclient (old) users configured on the UCx Server under **System** -\> **Users**, are not used by Infinity One.

# <a id="issues"></a>Known Issues

*   Deleting users is not currently supported. (Disable them instead)
*   Do NOT login to the same account on multiple devices. This is not currently supported and will result in undesirable behaviour.
*   Some limited actions can cause the page to reload which will drop any active calls.
*   Some permissions are not checked properly, especially it the default permissions are changed. Specifically the admin only related permissions.
*   Only Google Chrome and Chrome Canary browsers are supported.
*   The WebRTC client is not yet supported on mobile devices, but the chat part of the app should work reasonably.
*   There are a few issues with clearing the unread messages status and related banners under some scenarios.
*   There is no backup/restore feature of the database yet.
*   Video calls are not yet supported. Do NOT enable the feature in Administration -> WebRTC
