console.log('loading chan_user.js');

function to_map(element) {
  var ret = {}
  if (element) {
    let attributes = element.attributes;
    let keys = Object.keys(attributes)
    for (var i = 0; i < keys.length; i++) {
      let key = keys[i]
      ret[attributes[key].name] = attributes[key].value
    }
  }
  return ret
}

OneChat.on_connect(function(one_chat, socket) {
  console.log('userchan connect')
  let ucxchat = one_chat.ucxchat
  let chan = window.Rebel.channels.user.channel

  // TODO: This is a temporary work around to stop the duplicate messages.
  //       It however does not stop the duplicate channels on the server.
  if (one_chat.userchan) {
    console.warn('found an existing user channel', one_chat.userchan, chan);
    return;
  }
  one_chat.userchan = chan
  console.log('ucxchat', ucxchat)
  console.log('one_chat', one_chat)

  document.addEventListener('device_manager_init', (e) => {
    chan.push('webrtc:device_manager_init', {})
  });

  chan.on('room:update:name', resp => {
    if (debug) { console.log('room:update', resp) }
    $('li.link-room-' + resp.old_name)
      .removeClass('.room-link-' + resp.old_name)
      .addClass('.room-link-' + resp.new_name)
      .children(':first-child')
      .attr('title', resp.new_name).attr('data-room', resp.new_name)
      .attr('data-name', resp.new_name)
      .children(':first-child').attr('class', resp.icon + ' off-line')
      .next('span').html(resp.new_name)
  })
  chan.on('room:join', resp => {
    console.log('room:join', resp)
  })
  chan.on('room:leave', resp => {
    console.log('room:leave', resp)
  })
  chan.on('code:update', resp => {
    console.log('code:update', resp)
    OneUtils.code_update(resp)
  })
  chan.on('window:reload', resp => {
    console.log('location')
    if (resp.mode == undefined || resp.mode == false)
      window.location.reload()
    else
      window.location = '/home'
  })

  chan.on("toastr:success", resp => {
    toastr.success(resp.message)
  })

  chan.on("toastr:error", resp => {
    toastr.error(resp.message)
  })
  chan.on("room:mention", resp => {
    one_chat.roomManager.room_mention(resp)
  })
  chan.on("notification:new", resp => {
    one_chat.roomManager.notification(resp)
  })
  chan.on('message:preview', msg => {
    one_chat.message_preview(msg)
  })
  chan.on('update:alerts', msg => {
    console.log('update:alerts', msg)
    one_chat.roomManager.update_burger_alert()
  })

  console.log('finished starting user channel')
  // chan.join()
  //   .receive("ok", resp => { console.log('Joined user successfully', resp)})
  //   .receive("error", resp => { console.log('Unable to user lobby', resp)})

  chan.push('subscribe', {})
})
