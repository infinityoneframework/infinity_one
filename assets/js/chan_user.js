console.log('...chan_user.js loading')
UccChat.on_connect(function(ucc_chat, socket) {
  console.log('userchan connect')
  let ucxchat = ucc_chat.ucxchat
  let chan = window.Rebel.channels.user.channel
  ucc_chat.userchan = chan

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
    ucc_chat.utils.code_update(resp)
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
    ucx_chat.roomManager.room_mention(resp)
  })
  chan.on("notification:new", resp => {
    ucx_chat.roomManager.notification(resp)
  })
  chan.on('message:preview', msg => {
    ucx_chat.message_preview(msg)
  })
  chan.on('update:alerts', msg => {
    ucx_chat.roomManager.update_burger_alert()
  })

  console.log('finished starting user channel')
  // chan.join()
  //   .receive("ok", resp => { console.log('Joined user successfully', resp)})
  //   .receive("error", resp => { console.log('Unable to user lobby', resp)})

  chan.push('subscribe', {})
})
