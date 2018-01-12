# UcxUcc Changelog

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
