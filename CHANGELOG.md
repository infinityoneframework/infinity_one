# InfinityOne Changelog

## 1.0.0.beta11 (2018-04-09)

### Enhancements

### Bug Fixes

* [UCX-3896] Message replacement patterns with OneChat.refresh_users_status exception
* [UCX-3897] Fix Error when deleting user on system with only one admin.

## 1.0.0.beta11 (2018-04-05)

### Enhancements

* Add Getting started guide in help
* Add several page place holders
* Add new sections in help sidenav
* Add some nice page transitions in pages section
* Move the infinity_one_pages dependency into the one_pages plugin
* Added new Users Guide
* Added new Administration Guide
* Add site avatar to admin for customizing the desktop app icon
* Add site_client_name to admin for customizing the desktop app tooltip
* Add support for @@username and @@@username live status and status-message messages
* Move message_replacement_patterns to ChatGeneral Settings
* Optimize message_replacement_patterns processing with a run-time compiled module

### Bug Fixes

* Fix Typos on /pages
* User correct platform name in description on Windows and Linux download pages
* Fix Issue expanding help sections in sidenav
* Fix some markdown formatting issue on help pages
* Fix the message posting issue on MS Edge

## 1.0.0.beta10 (2018-04-03)

### Enhancements

* Add InfinityOnePages package including download desktop app support
* Update the default home page default text
* Support markdown for home page text entry
* Added support for reset admin changes back to default value

### Bug Fixes


## 1.0.0.beta9 (2018-03-28)

### Enhancements

* Added local help framework with couple help pages (WIP)
* Use Message poster avatar in desktop notifications
* Added server_settings public API for use by desktop clients
* [UCX-3852] Double markup characters and match on leading and trailing spaces

### Bug Fixes

* [UCX-3869] require either first char of leading space to trigger app pop-ups.
* [UCX-3868] Stop /unknown command for eating the message

## 1.0.0.beta8 (2018-03-26)

### Enhancements

* Add support for the upcoming desktop app
  * Fix exception in notification JS
  * Add page_params for the desktop app
* Add couple new help pages for the desktop app - WIP

### Bug Fixes

## 1.0.0.beta6 (2018-03-19)

## Enhancements

* Allow users to login with either username or email
* Change site_name default to Infinity One
* Use site_name title on authentication pages
* Add notification count to page title

### Bug Fixes

* [UCX-3839] Fix no messages when num messages eq page size
* [UCX-3838] Fix url previews for new message
* [UCX-3842] Fix up arrow edit exception error
* [UCX-3843] Fix message popup selection in middle of text

## 1.0.0.beta5 (2018-03-12)

## Enhancements

* Only display authorized message cog buttons
* Show all roles in Admin user card
* Remove scoped user_roles when channel removed
* Support invitation delete

### Bug Fixes

* Check edit message permissions

## 0.3.2 (2018-01-xx)

## Enhancements

* Show alerts and notifications immediately on browser blur
* Reduce clear unreads times from 2000 to 1000 msec.
* Moved message_agent from Agent to GenServer
* Changed desktop notification title to 'Message from @username'
* Backup and Restore feature
* Implement Delete User
* UCX-3815 - Conversations have old date
* Update rooms after admin delete room
* UCx-3798 - Add owner role when creating a room.
* Add fix_owner_roles release task

### Bug Fixes

* Off-line users now see alerts generated while off-line when logging back in
* Fixed hiding unread-bar when last message not visible on browser focus.
* Close open subscriptions when logging out or closing browser.
* Fix administration permissions
* Fix create and delete room permission checks


## 0.3.1 (2018-01-05)

## Enhancements

### Bug Fixes

* Enforce many permissions for guest accounts
* Fix message search exception


## 0.3.0 (2018-01-01)

## Enhancements

* Implement admin add user
* Random password does not show by default. Added separate Show button
* Added the ability for administrators to set/remove channel default setting

### Bug Fixes

* Fix admin edit user
* Fix Random password feature
* Fixed Exceptions updating room settings

## 0.2.6 (2018-02-19)

## Enhancements

* Support Avatar upload and change
* Changing view details in accounts settings automatically updates UI
* Converge OneConsole and OneChat.Console into OneConsole
* Added new Accounts section in Admin
* Remove register link from login page by admin option
* Remove forget password link from login page by admin option
* Remove remember me link from login page by adamin option
* Support Allow users delete own account
* Support Allow user profile change
* Support Allow username changes in profile page
* Support Allow email change in in profile page
* Support Allow password change in profile page
* Update message role tabs when a role is added/removed for a user
* Added new pin-message permission
* Check permissions for pinning messages
* Update open flex panel when starred, pinned, and mentions are added or removed
* Fix @here and @ll mentions.
* Add @all! mention to alert all logged in users
* Add new caution announcement
* Include @all, @all!, and @here in search patterns
* Add new permissions to the database on startup
* Add new @all! permission
* Enforce new @all, @here, and @all! permissions
* Add support to change permissions in admin
* Support adding, removing and assigning roles
* Fix update mentions regression

### Bug Fixes

* Fix permissions checks for room-edit
* Fix issue having multiple subscriptions open for the same user
* Fix tagging own mentions in flex panel
* Fix exception when clicking on a mention for an invalid user.

## 0.2.5 (2018-02-09)

## Enhancements

* New Setup page to help configure new systems
  * Setup the host name to ensure emails have the correct url
  * Add admin account so we don't need to seed one
  * Allow user to name and create the default channel
  * Configure the email from_name and from_email settings
* Add Config file updater
* Add restart server feature
* Moved the `Administration` menu link above `My Account`
* Added creating new N-way channel when mentioning someone in a DM channel
* Disable WebRTC channel when WebRTC disabled.
* Presence overrides remain after logout and login

### Bug Fixes

* Fix issue with presence not showing on initial login

## 0.2.4 (2018-02-08)

## Enhancements

* Add configuration of the uploads path
* Don't reload page when using the conversation button from members list
* Redesigned Message handling and broadcasting
* Proof of concept for Messaging Rest API
* Removed some code complexity around messaging
* Added support for all messages audio alerts and system settings
* Added audio mode in room notifications panel
* Added support for all messages desktop notifications
* Optimized how Direct Message channels are manged.

### Bug Fixes

* [UCX-3770] Fix JS exception when selecting from a message popup
* Trim a message before saving it
* [UCX-3764] Allow user to hide the first listed room
* [UCX-3769] Fix incoming message does not scroll window down
* [UCX-3766] Move the flex-nav scollbars to the right of page
* [UCX-3731] Fix rendering create channel after more channels
* Don't broadcast message popup selections
* Fixed message timestamps
* Fixed reaction tool tips
* Fixed subscribing 3rd party in direct channel with @mention

## 0.2.3 (2018-02-02)

### Bug Fixes

* Fix the admin info refresh button
* Increase the height of the layout body content textarea
* Fix the cancel button on the admin pages
* Move the layout home page body field from string to text
* Fixed Message order issue when dynamically loading more pages up and down
* Fixed loading more prev and next animation
* Fixed messages screen lockup issue caused by not clearing page loading animation
* Fixed more messages up and down detection
* Fixed links in new messages banner
* Refactored a lot of the JS related to room message handling
* Added direction detection to scroll so scrolling up does not trigger load more next at the bottom of the page
* Fixed double fetch issues when opening a new room

## Enhancements

* Changed message pagination to use 3rd party library
* Added previous messages banner when contents less than window size and scroll detection does not work
* Added 1px scroll at top and bottom of window so load more can be properly detected when at the top or bottom of the page
* Move the sidenav scrollbar to the right side
* Add Status Message History Editing and Deleting
* Added Uploads disk quota feature
* Added Uploads disk usage on Admin info page
* Added Application uptime to Admin info page
* Removed the page load on selecting direct rooms

## 0.2.2 (2018-01-18)

### Bug Fixes

* [UCX-3566] Closing Admin section now closes Admin panels
* Fixed issues with new status message not showing up in select box until page reload
* [UCX-3699] Fixed editing message shows up in other user's input box
* [UCX-3703] Fix incorrect message box after making room public
* [UCX-3661] Fix broken auto grow message input box and make it shrink correctly
* [UCX-3686] Fix mention linking for usernames with .
* [UCX-3707] Fixed auto linking phone number errors
* Use inserted_at for date and times in messages.
* Fix next day indication for pinned, starred, and mentions.
* [UCX-3651] Updated message grouping after a message delete.
* [UCX-3717] Support auto linking markdown style links
* [UCX-3716] Allow auto linking in markdown

### Enhancements

* [UCX-3670] Allow Bots in public channels only
* [UCX-3672] Add ability to collect and report healh stats
* [UCX-3667] Improve response time by replacing exec_js with broadcast_js
* [UCX-3679] Added status messages
* Implement SideNav Channel Search
* Implement SideNav More Channels Filters
* Implement SideNav Create channel
* Add message searching

## 0.2.1 (2018-01-15)

### Enhancements

### Bug Fixes

* [UCX-3652] Updated the italics markup regex so it does not match with _ in html tags
* [UCX-3632] Fixed audio file uploads
* [UCX-3649] Fixed backspace in empty message box shows send button
* [UCX-3649] Enter key to send message does not insert a \n in the message
* [UCX-3647] Close tool-tip when user removes reaction

## 0.2.0 (2018-01-12)

### Enhancements

* [UCX-3628] Only allow message edit if text area is empty

### Bug Fixes

* [UCX-3442] Adding mention while editing message now adds the mention to the DB
* [UCX-3639] Fixed display order of mentions in the flex panel
* [UCX-3638] Fixed issue with Bot responses displayed multiple times
* [UCX-3640] Fixed Bot avatar on page reload
* [UCX-3635] Fixed user able to delete their own message
* [UCX-3642] Added a unique constraint and validation on starred_messages
* [UCX-3643] Added a unique constraint and validation on pinned_messages
* [UCX-3627] Up arrow edit only selects messages from the main window and check for nil
* [UCX-3644] Fixed incorrect avatar in account box
* [UCX-3645] Message send button now works

### Backward incompatible changes

