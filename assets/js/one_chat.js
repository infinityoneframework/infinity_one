// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":

console.log('loading one_chat');

window.root = global || window

import hljs from "highlight.js"
require('./emoji.js')
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

window.OneChat = {
  run: function() {
    console.log('OneChat.run ...') //, this)
    let one_chat = this

    this.socket = window.Rebel.socket

    setTimeout(() => {
      $('#initial-page-loading').remove();
      window.OneUtils.remove_page_loading();
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
      OneUtils.remove_page_loading()

    }, 200)

    $('body').on('submit', 'form', function() { return false; });

  },
  chan_user: "user:",
  chan_room: "room:",
  chan_system: "system:",
  chan_wiki: "wiki:",
  debug: false,
  socket: undefined,
  typing: false,
  ucxchat: window.ucxchat,
  onLine: true,
  loads: [],
  connects: [],
  socket: false,
  notificationsEnabled: true,
  Presence: require('phoenix').Presence,
  on_load: function(f) {
    this.loads.push(f)
  },
  on_connect: function(f) {
    this.connects.push(f)
  },
  message_preview: function(msg) {
    setTimeout(() => {
      let bottom = OneUtils.is_scroll_bottom()
      if (msg.html)
        $('#' + msg.message_id + ' div.body').append(msg.html)
      if  (bottom) {
        OneUtils.scroll_bottom()
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
  normalize_message: (message_id) => {
    var message = $('#' + message_id);
    var username = OneChat.ucxchat.username;
    console.log('normalize message', message_id, message);
    if (message.data('username') != username){
      message.removeClass('own');
    }
    if (message.data('date') != message.prev().data('date')) {
      message.addClass('new-day');
    }
    // message.find(`a.mention-link[data-username="${username}"]`)
    //   .addClass('mention-link-me background-primary-action-color');
    message.find('pre code').each(function(i, block) {
        hljs.highlightBlock(block)
    });
  },
  onload: function() {
    console.log('socket ready ...')

    $('body').on('submit', '.message-form', e => {
      if (this.debug) { console.log('message-form submit', e) }
    })

    this.navMenu.setup()

    $('#initial-page-loading').remove()

    window.cv = this.checkVisible
  }
}

require('./autogrow')
require('./side_nav')
require('./one_webrtc')
require('./admin')
require('./admin_flex_bar')
require('./notifier')
require('./room_manager')
require('./room_history_manager')
require('./file_upload')
require('./menu')
require('./message_popup')
require('./message_cog')
require('./utils')
require('./chat_dropzone')
require('./typing')
require('./main')
require('./utils')
require('./chan_user')
require('./chan_system')
require('./chan_room')
require('./chan_wiki')
require('./messages')

import * as cc from "./chat_channel"

window.page_params = {
  default_language: "en",
  default_language_name: "English",
  ucxchat: ucxchat,
};
