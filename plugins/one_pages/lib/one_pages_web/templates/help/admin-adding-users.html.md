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