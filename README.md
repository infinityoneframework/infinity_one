# UcxUcc - A Team Collaboration Suite

[![Build Status](https://travis-ci.org/smpallen99/ucx_ucc.png?branch=master)](https://travis-ci.org/smpallen99/ucx_ucc) [![License][license-img]][license]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> <center><b>NOTE</b></center>
>
> This is an E-MetroTel dev branch that has some minor tweaks for their
> commercial plugins. It fill not work without the commercial plugins and
> should not be used by the open source community.
>

UcxUcc is a simple but powerful team collaboration suite of applications designed to improve communications, information sharing and productivity for the businesses small and large.

Checkout an older version's [Live Demo](http://chat.spallen.com). Click on the [Register a new account](http://chat.spallen.com/registrations/new) link on the sign in page to create an account. This is actually the live demo of the [ucx_chat](https://github.com/smpallen99/ucx_chat) project. [ucx_ucc](https://github.com/smpallen99/ucx_ucc) is based on a significantly different architecture that allows for adding custom plug-ins without extending the base project.

![Screen Shoot](priv/images/screen_shot_1.png)

This innovative suite of tools enhances business productivity with:

* An enterprise class telephone that is available anywhere your employees have an Internet connection
* Share important messaging conversations that would normally be hidden in point to point conversations with tools like SMS and Skype.
* Choose the most effect method of communications a glance at their on-line or on the phone presence.
* Upload, search and download documents, images, videos, and audio files in chat rooms and share with the rest of your team.
* Start a private conversations with direct messages
* Pin important messages for quick access for everyone
* Star important messages for your quick reference
* Track popularity of messages with message reactions and see who reacted
* Never miss an important message with an advanced notification framework that provides audible, desktop, SMS, and email notifications. Control the noise by customizing the notifications on a room by room basis.

And the bast part is that the data is safe with encrypted connections between your browser and the server. All the data is stored on your own server, not on someone else's cloud.

<img src="priv/images/screen_shot_2.png" height="400px">

## Available Features

* Multiple channel types (public, private, direct messgaes)
* Favorite channels
* @mentions with audible and badge notifications
* Presence with override
* Message editing, pinning, starring, deleting
* About 30 slash commands (create room, invite user, ...)
* Autolink and preview urls
* Drag and drop file update with image and video preview
* Emoji support with picker
* Message reactions
* Unread message handling
* Customizable Role and Permission system
* Some basic Bot experimental support
* Code syntax highlighting
* Profile editing and admin pages
* Very configurable
* Markdown support in messages
* Configurable message parsing (Regex.replace/3 list)
* and more ...

## Feature Roadmap

* Replace the Rock.Chat UI with a new original design
* Peer to peer Video
* Peer to peer Audio
* Presence adapters for on-the-phone presence with Asterisk PBX (commercial plugin)
* Mobile clients and Push notifications
* Email and SMS notifications
* OTR Conversations
* Live chat feature
* 3rd party integration (web hooks, Rest API)
  * BitBucket
  * Github
  * Jira
  * ...
* OAuth and LDAP
* XMPP Integration
* Internatization (Much of the UI uses gettext already)
* UI theming
* Documenation for other databases and flavours of *nix
* and more ...

<img src="priv/images/screen_shot_3.png" height="400px">

## Archtectural Notes

* Elixir & Phoenix Backend
* Light JS frontend (jQuery only)
* After initial page load, channels are used for UI rendering. HTML is renedered on the server and pushed to the client over channel
* Originally build as a stand-a-lone single app.
* In the process of refactoring it to be extensible through plugins
* We will be using it for a client framework with initial support for the chat app and our commerical WebRTC softphone (delerved as a plugin)
* This is a work in progress and requires a lot of clean up before production release
* I've experiemented with serveral diffent approaches of channel -> JS rendering, channel message routing, etc. I still need to pick an approach and refactor the other areas for consistency.

<img src="priv/images/screen_shot_4.png" height="400px">

## Other Notes
### Backup Database

```bash
mysqldump --add-drop-database --add-drop-table -u user --password=secret --databases ucx_ucc_prod > ucx_ucc.sql
```

### Restore Database

```bash
mysql -u user -psecret < ucx_ucc.sql
```

### Install Dependencies

#### ffmpeg

```bash
rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el6/x86_64/nux-dextop-release-0-2.el6.nux.noarch.rpm
yum install ffmpeg ffmpeg-devel -y
```
#### ImageMagick

```bash
yum install -y ImageMagick ImageMagick-devel
```

### Running Migrations

Don't uses the standard `mix ecto.migrate` since it will not pickup the migrations from the plugins. Instead, run the followind command.

```bash
mix unbrella.migrate
```

However, you can still run the following commands since they are aliased to use `mix unbrella.migrate`.

```bash
mix ecto.setup
mix ecto.setup
mix test
```

## Contributing

We appreciate any contribution to UcxUcc. Check our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and [CONTRIBUTING.md](CONTRIBUTING.md) guides for more information. We usually keep a list of features and bugs [in the issue tracker][1].

  [1]: https://github.com/smpallen99/ucx_ucc/issues
## Acknowlegemets

The UI for this version of the project is taken (with some modifications) directly from [Rocket.Chat](https://rocket.chat/).
## License

`UcxUcc` is Copyright (c) 2017-2018 E-MetroTel

The source code is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
