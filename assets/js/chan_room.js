 // window.Rebel.channels.user.channel

console.log('loading chan_room.js');

function start_room_channel(one_chat, socket) {
  console.log('chan_room connect')
  let ucxchat = one_chat.ucxchat
  let room = ucxchat.room
  let debug = one_chat.debug
  let typing = one_chat.typing
  // Now that you are connected, you can join channels with a topic:
  let chan = window.Rebel.channels.room.channel

  if (debug) { console.log('start socket', ucxchat) }
  console.log('...', OneUtils)

  OneUtils.push_history();

  Rebel.additional_payloads.push(function(sender, event) {
    // console.log('additional_payloads', sender, event)
    if (!sender) {
      return {};
    }
    var handlers = ['message_keydown', 'click_popup'];
    var handler = sender.getAttribute('rebel-handler');
    var opened, results, position, app;

    if (handler == 'message_keydown' || handler == 'click_popup') {
      var opened = false;
      var results = document.querySelector('.message-popup-results');
      var position = document.querySelector(
        '.message-popup-results .message-popup-position');
      var app = "";
      if (position) {
        app = position.dataset["app"];
        }

      if (results && results.innerHTML != "") {
        opened = true;
      }
    }

    if (handler == 'message_keydown') {
      // we have the text area
      return {
        text_len: sender.value.length,
        caret: OneUtils.getCaretPosition(sender),
        message_popup: opened,
        popup_app: app
      }
    } else if (handler == 'click_popup') {
      // console.log('click_popup', sender);
      var input = document.querySelector('.input-message');

      var res =  {
        value: input.value,
        text_len: input.value.length,
        caret: OneUtils.getCaretPosition(input),
        message_popup: opened,
        popup_app: app
      }
      // console.log('res', res);
      return {
        value: input.value,
        text_len: input.value.length,
        caret: OneUtils.getCaretPosition(input),
        message_popup: opened,
        popup_app: app
      }
    }
  });

  chan.on("user:entered", msg => {
  })

  chan.on("user:leave", msg => {
  })

  chan.on("message:new", msg => {
    if (debug) { console.log('message:new current id, msg.user_id', msg, ucxchat.user_id, msg.user_id) }
    one_chat.Messages.new_message(msg)
  })
  chan.on("message:update", msg => {
    if (debug) { console.log('message:update current id, msg.user_id', msg, ucxchat.user_id, msg.user_id) }
    one_chat.Messages.update_message(msg)
  })

  chan.on("typing:update", msg => {
    if (debug) { console.log('typing:update', msg) }
    typing.update_typing(msg.typing)
  })

  chan.on("room:update", msg => {
    one_chat.roomManager.update(msg)
  })

  chan.on("toastr:success", resp => {
    window.toastr.success(resp.message)
  })

  chan.on("toastr:error", resp => {
    window.toastr.error(resp.message)
  })

  chan.on("sweet:open", resp => {
    $('.sweet-container').html(resp.html)
  })

  chan.on('update:Members List', msg => {
    //console.log('update:Members List', msg)
    // console.log('update:Members List', msg, $('.tab-button[title="Members List"]').hasClass('active'))
  })
  chan.on('code:update', resp => {
    console.log('code:update', resp)
    OneUtils.code_update(resp)
  })
  chan.on('code:update:reaction', resp => {
    OneUtils.code_update(resp)
  })
  chan.on('reload', msg => {
    let loc = msg.location
    if (!loc) { loc = "/" }
    console.log('location', loc)
    window.location = loc
  })
  chan.on('message:preview', msg => {
    one_chat.message_preview(msg)
  })

  one_chat.roomchan = chan;

  console.log('....going to clear')
  one_chat.roomManager.clear_unread()
  console.log('....going to new_room')
  one_chat.roomManager.new_room()
  console.log('....going to scroll_new_window')
  one_chat.roomHistoryManager.scroll_new_window()

  console.log('....going to run')
  one_chat.main.run(one_chat)
  console.log('....going to update_mentions')
  one_chat.roomManager.updateMentionsMarksOfRoom()

  $('.messages-box .message').find('pre code').each(function(i, block) {
    hljs.highlightBlock(block)
  });

  if (window.Rebel) {
    window.Rebel.set_event_handlers('#flex-tabs')
  }

  console.log('....going to close')
  one_chat.navMenu.close()
  console.log('....done')

}

OneChat.on_connect(function(one_chat, socket) {
  console.log('running room channel on_connect');
  start_room_channel(one_chat, socket)

  $('body').on('restart-socket', () => {
    console.log('received restart-socket event', OneChat)
    Rebel.run_channel("room", Rebel.get_rebel_session_token('room'), OneChat.ucxchat.room)
    start_room_channel(one_chat, socket)
  })
})
