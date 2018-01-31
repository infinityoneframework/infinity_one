# UcxUcc Changelog

## 1.0.0-alpha15 (2018-01-31)

### Enhancements

* [UCX-3729] Fix Dynamic Message Loading
  * Changed message pagination to use 3rd party library
  * Added previous messages banner when contents less than window size and scroll detection does not work
  * Added 1px scroll at top and bottom of window so load more can be properly detected when at the top or bottom of the page
* [UCX-3749] Move the sidenav scrollbar to the right side
* [UCX-3719] Add Status Message History Editing and Deleting
* [UCX-3589] Include ssl certificates to configuration

### Bug Fixes

* [UCX-3729] Fix Dynamic Message Loading
  * Fixed Message order issue when dynamically loading more pages up and down
  * Fixed loading more prev and next animation
  * Fixed messages screen lockup issue caused by not clearing page loading animation
  * Fixed more messages up and down detection
  * Fixed links in new messages banner
  * Refactored a lot of the JS related to room message handling
  * Added direction detection to scroll so scrolling up does not trigger load more next at the bottom of the page
  * Fixed double fetch issues when opening a new room
* [UCX-3745] Fix Volume Down title on WebRTC Client
* Fixed Upload extension uppercase issue

## 1.0.0-alpha14 (2018-01-26)

### Enhancements

* [UCX-3739] Added ability to control ClientSm logging for some messages

### Bug Fixes

* [UCX-3733] Fixed Mscs and Phone presence issues when Astrisk dies or restarts
* [UCX-3701] Fixed phone presence stops working

## 1.0.0-alpha12 (2018-01-23)

### Enhancements

* [UCX-3708] Made the WebRTC client compact theme the default
* [UCX-2724] Implement SideNav Channel Search
* [UCX-3725] Implement SideNav More Channels Filters
* [UCX-3726] Implement SideNav Create channel
* [UCX-3727] Add message searching
* Added Mac Address display on phone settings page

### Bug Fixes

* [UCX-3664] Fixed incoming call notification bar
  * Redesign Phone presence server for Asterisk 13
  * Fixed the call notification alert so it clears correctly
  * Fixed the answer button on the notification bar
* [UCX-3654] Ucc: Headset configuration failure causes speech path issue on Ucx Ucc phone client
* Fixed issues with new status message not showing up in select box until page reload
* [UCX-3699] Fixed editing message shows up in other user's input box
* [UCX-3703] Fix incorrect message box after making room public
* [UCX-3661] Fix broken auto grow message input box and make it shrink correctly
* [UCX-3686] Fix mention linking for usernames with .
* [UCX-3707] Fixed auto linking phone number errors
* [UCX-3607] Fixed the blue flashing led
* [UCX-3696] Remove the shift toggle aux pad shortcut on the compact theme
* [UCX-3722] Use inserted_at for date and times in messages.
* [UCX-3723] Fix next day indication for pinned, starred, and mentions.
* [UCX-3651] Updated message grouping after a message delete.
* [UCX-3717] Support auto linking markdown style links
* [UCX-3716] Allow auto linking in markdown
* [UCX-3718] Add styles to status-messages to ensure options are visible

## 1.0.0-alpha11 (2018-01-16)

### Enhancements

* [UCX-3670] Allow Bots in public channels only
* [UCX-3672] Add ability to collect and report healh stats
* [UCX-3671] Enable msec resolution timestamps in syslog
* [UCX-3667] Improve response time by replacing exec_js with broadcast_js
* [UCX-3672] Using a different syslog package now with better resolution
* [UCX-3681] Improved the logger format, reducing noise
* [UCX-3679] Added status messages
* [UCX-3878] Added labels to the presence blocks on accounts drop-down

### Bug Fixes

* [UCX-3566] Closing Admin section now closes Admin panels
* [UCX-2605] Fix client initialization after reset
* Update ex_ami to support asterisk 13

## 1.0.0-alpha9 (2018-01-14)

### Enhancements

* [UCX-3592] Added support for a full 120 WebRTC client programmable keys
* [UCX-3655] Added a new WebRTC client compact theme supporting 15 keys per strip
* [UCX-3656] Implemented the WebRTC client Settings page
* [UCX-3657] WIP: Prototype of replacing WebRTC client icons

### Bug Fixes

* [UCX-3652] Updated the italics markup regex so it does not match with _ in html tags
* [UCX-3632] Fixed audio file uploads
* [UCX-3649] Fixed backspace in empty message box shows send button
* [UCX-3649] Enter key to send message does not insert a \n in the message
* [UCX-3647] Close tool-tip when user removes reaction
* [UCX-3648] Cleaned up the markdown styles for bullet and numbered lists

## 1.0.0-alpha8 (2018-01-12)

### Enhancements

* [UCX-3628] Only allow message edit if text area is empty

### Bug Fixes

* [UCX-3634] Convert log warnings to debug where appropriate. Use fn -> ... end
* [UCX-3625] Fix in_use phone presence to use red phone, not busy icon.
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
