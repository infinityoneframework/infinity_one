*   [Chapter 1 - Introduction](#Chapter1)
*   [Chapter 2 - Rooms](#Chapter2)
    *   [Channels](#Chapter2-1)
    *   [Direct Messages](#Chapter2-2)
    *   [Private Groups](#Chapter2-3)
*   [Chapter 3 - Room Operations](#Chapter3)
    *   [Favorites](#Chapter3-1)
    *   [Joining](#Chapter3-2)
    *   [Hiding and Leaving](#Chapter3-3)
*   [Chapter 4 - Messaging](#Chapter4)
    *   [Sending](#Chapter4-1)
    *   [Mentions](#Chapter4-2)
    *   [Attachments](#Chapter4-3)
    *   [Other Functions](#Chapter4-4)
*   [Chapter 5 - Right Icon Menu](#Chapter5)
*   [Chapter 6 - Slash Commands](#Chapter6)
*   [Chapter 7 - FAQ](#Chapter7)

# <a name="Chapter1"></a>Chapter 1 - Introduction

Infinity One is a web-based chat service and soft phone provided on the UCx Server that is ideal for companies wanting to privately host their own chat service.

To access Infinity One from a web broswer, enter the IP address or hostname of the UCx Server followed by ' **:4021** '.

For example: **http://192.168.1.200:4021**

# <a name="Chapter2"></a>Chapter 2 - Rooms

Conversations in Infinity One are organized into chat rooms, there are 3 different types of rooms:

1.  Channels
2.  Direct Messages
3.  Private Groups

### <a name="Chapter2-1"></a>Channels

Channels are public, used for conversations that are open to all users to join. New users joining the channel can read all information previously published on the channel.

Channels are useful for sharing information with your users, for example, you can create a "Help" channel to share tips on using Infinity One.

To create a channel, type the command `/create` followed by the channel name in the message text box:


    /create #channel

### <a name="Chapter2-2"></a>Direct Messages

Direct messages are private one-to-one conversations between two users. When you send a chat message to another user, it is automatically a direct message.

To start a direct message with another user, go to DIRECT MESSAGES on the left-hand panel, click on "**More Users...**" link to see all users, then select the user.

### <a name="Chapter2-3"></a>Private Groups

Private groups are private, not open to the public. It is visible only to their members. Private groups can be joined by invitation only.

The administrator sets the permissions that determine who can invite others to a private group. By default, only administrators, room owners, and moderators can invite others to join a private group.

To create a private group:

1.  First create a public channel
2.  Click on ![](/images/ucc-info-icon.png)  located on the [Right Icon Menu](#RMenu).
3.  Enable the **Private** settting.
    ![](/images/ucc-private.png)

To invite users to the group, enter the following command:

    /invite @username

# <a name="Chapter3"></a>Chapter 3 - Room Operations

The various rooms are listed on the left-hand navigation panel and organized according to their types.

### <a name="Chapter3-1"></a>Favorites

To favorite a channel, click on the star icon in the upper left corner of the message area (next to the room name).
 ![](/images/ucc-favourite1.png)
The star is then highlighted. To unfavorite a channel, just click on the star icon again.
 ![](/images/ucc-favourite2.png)
Highlighted channels are listed under **Favorites** on the left-hand panel. 
![](/images/ucc-favourite3.png)

### <a name="Chapter3-2"></a>Joining channels

Your channels are listed on the left-hand pane under **CHANNELS(X)**, where X represents the number of channels you have joined.
To view all available channels, click on the "**More channels...**" link.
Click on a channel to preview its contents. If you want to join it, click on the ![JOIN](/images/ucc-join%20%282%29.png) button.

### <a name="Chapter3-3"></a>Hiding and leaving channels

When you hover your mouse over a channel listed on the left-hand pane, you will see two icons appear to the right of the channel name: ![JOIN](/images/ucc-hide.png) Hide\_room and Leave\_room.
To hide a room is to remain a member of the channel but to remove it from your list of channels on the left-hand pane.
To leave a room is to no longer be a member of the channel.
Click on the corresponding icon to "hide" or "leave" a room.

# <a name="Chapter4"></a>Chapter 4 - Messaging

### <a name="Chapter4-1"></a>Sending

Sending chat messages is simple:

*   First select the channel, user or private group from the left-hand panel
*   Then type your message in the message box and press the **Enter** key or the **Send** ![](/images/ucc-send.png) button.

If you want to insert a new line without sending the message, press **Shift+Enter**.
Emojis can be added to your message by clicking on the emoji icon located on the left of the message box.

### <a name="Chapter4-2"></a>Mentions

You can "mention" someone by typing @ followed by their username, for example @john. Enter @ and start typing the username, a drop-down list will appear where you can select the desired user.

A user can be selected from the list by clicking on the username or using the keyboard arrow keys to scroll up and down then select by pressing the tab key.

When someone is mentioned in a room, they will get a desktop notification and also a badge count beside the room name if they are not already in the room.
![](/images/ucc-badgecount.png)
Each of your mentions are also listed in the Mentions list when you click on  ![](/images/ucc-mentions-icon.png)  located on the [Right Icon Menu](#RMenu).

### <a name="Chapter4-3"></a>Attachments

To upload a file, there are 2 options:

*   Click on the paperclip ![](/images/ucc-uploadicon.png) icon and select the file, enter a description and click **OK** to upload.
    ![](/images/ucc-uploadfile.png)
*   Drag and drop the file onto the message box.
    ![](/images/ucc-dragdrop.png)

For each uploaded file, you can edit the file name and add a description. A number of file types are supported including images, videos, audio files, pdfs, and office documents.

The supported file types is configurable by the administrator.

### <a name="Chapter4-4"></a>Other Functions

You can access other messaging functions by hovering over the message, then click on the Gear ![](/images/ucc-gear-icon.png) icon that appears, an expanded list of functions is then displayed: ![](/images/ucc-gearadmin.png)

The messaging functions supported by Infnity One include:
![](/images/ucc-edit-icon.png) Edit - you can edit the message that was sent
![](/images/ucc-delete-icon.png) Delete - you will be prompted to confirm deletion of the message
![](/images/ucc-star-icon.png)Star - message will appear in the Starred Messages list that only you can see
![](/images/ucc-pin-icon.png)Pin - message will appear in the Pinned Messages list for everyone in the room to see
![](/images/ucc-emoji-icon.png)Emoji reaction - you will be prompted to select an emoji and the selected emoji will appear beneath the message

The functions available depend on the permissions configured by the administrator. The default permission for a normal user typically does not allow the PIN function.

# <a name="RMenu"></a>Chapter 5 - Right Icon Menu

Located on the right side of the screen, there is an icon menu that provides quick access to the following functions:

*   Info
*   Search
*   Members List or User Info
*   Notifications
*   Files List
*   Mentions
*   Starred Messages
*   Pinned Messages
*   Device Settings
*   WebRTCClient

![](/images/ucc-right-menu.png)![](/images/ucc-right-menu2.png)

### <a name="Chapter5-1"></a>Info ![](/images/ucc-info-icon.png)

Displays information and settings for the Room. You can change the room settings here and also delete the room.
![](/images/ucc-room-info.png)

### <a name="Chapter5-2"></a>Search ![](/images/ucc-search-icon.png)

Allows you to search for messages in the current room that matches the search text. You can search using RegExp, e.g. /^text/.

### <a name="Chapter5-3"></a>Members List or User Info ![](/images/ucc-members-icon.png) ![](/images/ucc-user-icon.png)

Displays the list of members who have joined the Channel or Private Group. For Direct Messages, it displays the User information.

### <a name="Chapter5-4"></a>Notifications ![](/images/ucc-notifications-icon.png)

To configure the notification settings for the room.
![](/images/ucc-notifications.png)

### <a name="Chapter5-5"></a>Files List ![](/images/ucc-attachments-icon.png)

Displays the list of attachments that have been uploaded for the room.

### <a name="Chapter5-6"></a>Mentions ![](/images/ucc-mentions-icon.png)

Displays the list of messages where you have been mentioned.

### <a name="Chapter5-7"></a>Starred Messages ![](/images/ucc-star-icon_0.png)

Displays the list of starred messages. Starred messages are personal, only you can see them.

### <a name="Chapter5-8"></a>Pinned Messages ![](/images/ucc-pin-icon_0.png)

Displays the list of pinned messages. Pinned messages are public, can be viewed by all members of the room.

### <a name="Chapter5-9"></a>Device Settings ![](/images/ucc-device-settings-icon.png)

To configure the input/output audio and video devices used by the application.
![](/images/ucc-device-settings.png)

### WebRTC Client ![](/images/ucc-webrtcclient-icon.png)

Displays the WebRTC client that is used for making phone calls.
![](/images/ucc-webrtcclient.png)

WebRTC must first be enabled to access this feature. To enable WebRTC:

*   Click on the Account Box (top left corner)
*   Select **My Account** -> **Phone**
*   Switch on the **Enable WebRTC** toggle

![](/images/UCC-client-6.png)

### Client Settings ![](/images/ucc-clientsettings-icon.png)

The client settings icon is visible only when the WebRTC client is displayed. The form allows you to configure the theme and number of keys for your WebRTC client.
![](/images/ucc-clientsettings.png)

# <a name="Chapter6"></a>Chapter 6 - Slash Commands

Some of the functions are accessed by typing '**/** ' followed by the command in the message text box. To view a list of available commands, simply type `**/** `and you can select from the list displayed.
Here is a list of the available slash commands:

Command

Description

    /archive #channel

To archive a channel

    /create #channel

To create a new channel.

    /invite @username

To invite a user to join this channel.

    /invite-all-to #channel

To invite all from the current channel to join the specified channel.

    /invite-all-from #channel

To invite all from the specified channel to join the current channel.

    /join #channel

To join the specified channel.

    /kick @username

To remove someone from the current channel.

    /leave

To leave the current channel.

# <a name="Chapter7"></a>Chapter 7 - FAQ

##### Can we send SMS text messages from this tool?

No, not yet. This is a future enhancement.

##### Can you control the audio notification?

You can control the audio notification under your account preferences or via the notification settings ![](/images/ucc-notifications-icon.png) for a specific room. There is no volume control.

##### How is the hashtag used here compared to the twitter/instagram/snapchat world?

The hash is a prefix to a room. When used in a message it is prepended to a valid room name, this allows a single click to get to the room. For example, you can write "... check out **#general** for general discussions...
