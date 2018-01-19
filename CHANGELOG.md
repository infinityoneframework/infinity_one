# UcxUcc Changelog

## 1.0.0-alpha12 (2018-01-xx)

### Bug Fixes

* [UCX-3664] Fixed incoming call notification bar
  * Redesign Phone presence server for Asterisk 13
  * Fixed the call notification alert so it clears correctly
  * Fixed the answer button on the notification bar

### Enhancements

## 1.0.0-alpha11 (2018-01-16)

### Bug Fixes

* [UCX-3566] Closing Admin section now closes Admin panels
* [UCX-2605] Fix client initialization after reset
* Update ex_ami to support asterisk 13

### Enhancements

* [UCX-3670] Allow Bots in public channels only
* [UCX-3672] Add ability to collect and report healh stats
* [UCX-3671] Enable msec resolution timestamps in syslog
* [UCX-3667] Improve response time by replacing exec_js with broadcast_js
* [UCX-3672] Using a different syslog package now with better resolution
* [UCX-3681] Improved the logger format, reducing noise
* [UCX-3679] Added status messages
* [UCX-3878] Added labels to the presence blocks on accounts drop-down

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
