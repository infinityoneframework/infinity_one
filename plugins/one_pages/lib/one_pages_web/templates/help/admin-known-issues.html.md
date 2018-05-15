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