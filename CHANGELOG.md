# UcxUcc Changelog

## 1.0.0-alpha10 (2018-01-15)

### Bug Fixes

* [UCX-3566] Closing Admin section now closes Admin panels

### Enhancements

* [UCX-3670] Allow Bots in public channels only
* [UCX-3672] Add ability to collect and report healh stats

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
