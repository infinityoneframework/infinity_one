// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":

console.log('ucc_chat.js loading...')

window.root = global || window

import hljs from "highlight.js"
// import * as swal from "./sweetalert.min"
require('sweetalert')
// window.Promise = require('es6-promise').Promise;

// window.swal = swal

// var socket = new Socket("/socket", {params: {token: window.user_token, tz_offset: new Date().getTimezoneOffset() / -60}})

// window.userchan = false
// window.roomchan = false
// window.systemchan = false

window.mscs = {}

hljs.initHighlightingOnLoad();

window.UccChat = {
  run: function() {
    console.log('UccChat.run ...') //, this)
    let ucc_chat = this

    this.socket = window.Rebel.socket

    setTimeout(() => {
      $('#initial-page-loading').remove()
      ucc_chat.utils.remove_page_loading()
    }, 1000)

    if (!window.ucxchat) {
      console.log('no ucxchat. exiting')
      return;
    } else {
      console.log('ucxchat continuing')
    }

    $('textarea.message-form-text').focus()

    setTimeout(() => {
      console.log('++++++ going to run loads', this.loads)
      this.loads.forEach((fx) => {
        fx(this)
      })
      console.log('going to run connects', this.connects)
      this.connects.forEach((fx) => {
        fx(this, this.socket)
      })

      console.log('going to run onload')
      this.onload()

      console.log('going remove_page_loading')
      this.utils.remove_page_loading()

    }, 200)

    $('body').on('submit', 'form', function() { return false; });

  },
  chan_user: "user:",
  chan_room: "room:",
  chan_system: "system:",
  debug: false,
  socket: undefined,
  typing: false,
  ucxchat: window.ucxchat,
  // scroll_to: roomManager.scroll_to,
  onLine: true,
  loads: [],
  connects: [],
  socket: false,
  Presence: require('phoenix').Presence,
  on_load: function(f) {
    this.loads.push(f)
  },
  on_connect: function(f) {
    this.connects.push(f)
  },
  // start_channels: function() {
  //   console.warn('running the channel timeout funs', window.Rebel.channels.user.channel )
  //   this.start_system_channel()
  //   this.userchan = window.Rebel.channels.user.channel
  //   this.start_user_chan()
  //   this.start_room_channel(typing)

  //   // TODO: Make this discoverable
  //   // window.ucc_webrtc.start_channel(socket)

  //   // device.set_webrtc(ucc_webrtc)
  //   // device.enumerateDevices()
  // },
  message_preview: function(msg) {
    setTimeout(() => {
      let bottom = this.utils.is_scroll_bottom()
      if (msg.html)
        $('#' + msg.message_id + ' div.body').append(msg.html)
      if  (bottom) {
        this.utils.scroll_bottom()
      }
    }, 100)
  },
  restart_socket: function() {
    let event = jQuery.Event( "restart-socket" );
    $("body").trigger(event)
  },
  checkVisible: function(elm, threshold, mode) {
    threshold = threshold || 0;
    mode = mode || 'visible';
    // elm = elm[0]
    var rect = elm.getBoundingClientRect();
    var wr = $('.wrapper.has-more-next')[0].getBoundingClientRect()
    var viewHeight = wr.top + wr.bottom
    var above = rect.bottom - threshold < 0;
    var below = rect.top - viewHeight + threshold >= 0;

    return mode === 'above' ? above : (mode === 'below' ? below : !above && !below);
  },
  isOnScreen: function(element) {
    var curPos = element.offset();
    var curTop = curPos.top;
    var screenHeight = $(window).height();
    return (curTop > screenHeight) ? false : true;
  },
  offlineContent: `
    <div class="alert alert-warning text-center" role="alert">
      <strong>
        <span class="glyphicon glyphicon-warning-sign"></span>
        Waiting for server connection,
      </stong>
      <a href="/" class="alert-link">Try now</a>
    </div>`,
  handleOffLine: function() {
    if (this.onLine) {
      $('.connection-status').html('').append(this.offlineContent).removeClass('status-online')

      this.onLine = false
    }
  },
  handleOnLine: function() {
    if (!this.onLine) {
      this.onLine = true
      window.location.reload()
      $('.connection-status').html('').addClass('status-online')
    }
  },
  randomString: (length, charList) => {
    let chars = charList
    if (!chars)
      chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$%#@!'
    var result = '';
    for (var i = length; i > 0; --i) result += chars[Math.floor(Math.random() * chars.length)];
    return result;
  },
  onload: function() {
    console.log('socket ready ...')

    $('body').on('submit', '.message-form', e => {
      if (this.debug) { console.log('message-form submit', e) }
    })
    .on('keydown', '.message-form-text', e => {
      console.log('keydown', e)
    })
    //   let event = new jQuery.Event('user:input')
    //   switch(e.keyCode) {
    //     case 38: // up arrow
    //     case 40: // down arrow
    //     case 9:  // TAB
    //       event.keyCode = e.keyCode
    //       $("body").trigger(event)
    //       return false
    //     case 8:  // BS
    //       event.keyCode = e.keyCode
    //       $("body").trigger(event)
    //     default:
    //       return true
    //   }
    // })
    .on('keypress', '.message-form-text', e => {
      // if (this.debug) { console.log('message-form-text keypress', e) }
      console.log('keypress', e)
    })
    //   if (e.keyCode == 13 && e.shiftKey) {
    //     return true
    //   }
    //   if(e.keyCode == 13) {
    //     if (this.messagePopup.handle_enter()) {
    //       // console.log('return ', $('.message-form-text').hasClass('editing'))
    //       if ($('.message-form-text').hasClass('editing')) {
    //         // console.log('editing submit...', $('li.message.editing').attr('id'))
    //         this.Messages.send_message({update: $('li.message.editing').attr('id'), value: $('.message-form-text').val()})
    //       } else {
    //         this.Messages.send_message($('.message-form-text').val())
    //       }
    //     }
    //     this.typing.clear()
    //     return false
    //   } //else if (e.keyCode == 64) {
    //   //   message_popup.open_users()
    //   //   return true
    //   // }

    //   let event = new jQuery.Event('user:input')
    //   event.keyCode = e.keyCode
    //   $("body").trigger(event)

    //   this.typing.start_typing()
    //   return true
    // })
    // .on('keypress', 'input', e => {
    //   console.log('keypress input', e.keyCode);
    //   // return false;
    //   // e.preventDefault();
    //   // if (e.KeyCode == 13) {
    //   //   UccChat.chan_user.push('')
    //   // }
    // })
    // .on('change', 'form', e => {
    //   console.log('keypress form',  e.target, e);
    //   // return false;
    //   // e.preventDefault();
    //   // if (e.KeyCode == 13) {
    //   //   UccChat.chan_user.push('')
    //   // }
    // })


    this.navMenu.setup()

    $('#initial-page-loading').remove()

    window.cv = this.checkVisible
  }
}

require('./autogrow')
require('./side_nav')
require('./ucc_webrtc')
require('./admin')
require('./admin_flex_bar')
require('./desktop_notification')
require('./room_manager')
require('./room_history_manager')
require('./file_upload')
require('./menu')
require('./message_popup')
require('./message_cog')
require('./message_input')
require('./utils')
require('./chat_dropzone')
require('./typing')
require('./main')
require('./utils')
require('./chan_user')
require('./chan_system')
require('./chan_room')
require('./messages')

import * as cc from "./chat_channel"
// import * as sweet from "./sweetalert.min"
// import * as device from './device_manager'
// import Typing from "./typing"
