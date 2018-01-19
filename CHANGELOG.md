# UcxUcc Changelog

## 0.2.2 (2018-01-18)

### Bug Fixes

* [UCX-3566] Closing Admin section now closes Admin panels
* Fixed issues with new status message not showing up in select box until page reload
* [UCX-3699] Fixed editing message shows up in other user's input box
* [UCX-3703] Fix incorrect message box after making room public
* [UCX-3661] Fix broken auto grow message input box and make it shrink correctly
* [UCX-3686] Fix mention linking for usernames with .

### Enhancements

* [UCX-3670] Allow Bots in public channels only
* [UCX-3672] Add ability to collect and report healh stats
* [UCX-3667] Improve response time by replacing exec_js with broadcast_js
* [UCX-3679] Added status messages

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

