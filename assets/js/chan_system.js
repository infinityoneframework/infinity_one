console.log('...chan_system.js loading')

// new presence stuff
let presences = {}

let Presence = require('phoenix').Presence

let formatTimestamp = (timestamp) => {
  let date = new Date(timestamp)
  return date.toLocaleTimeString()
}

let listBy = (user, {metas: metas, username: username}) => {
  // console.log('listBy user', user, 'metas', metas)
  return {
    user: user,
    username: metas[0].username,
    status: metas[0].status
  }
}

let userList = document.getElementById("UserList")

function update_presence(elem, status) {
  if (typeof elem === "object" &&  elem.length > 0) {
    elem.attr('class', elem.attr('class').replace(/status-([a-z]+)/, 'status-' + status))
  }
}

let render = (presences) => {
  Presence.list(presences, listBy)
    .map(presence => {
      let status = presence.status
      let elem = $(`.info[data-status-name="${presence.username}"]`)
      if (typeof elem === "object" &&  elem.length > 0) {
        elem.children(':first-child').data('status', status)
      }
      update_presence($(`[data-status-name="${presence.username}"]`), status)
    })
}

UccChat.on_connect(function(ucc_chat, socket) {
  let ucxchat = ucc_chat.ucxchat
  let chan = socket.channel(ucc_chat.chan_system, {user: ucxchat.username, channel_id: ucxchat.channel_id})

  console.log('chan_system connect')

  chan.onError( () => true )
  chan.onClose( () => true )

  chan.on('presence_state', state => {
    // console.log('presence_state', state)
    presences = ucc_chat.Presence.syncState(presences, state)
    render(presences)
  })
  chan.on('presence_diff', diff => {
    // console.log('presence_diff', diff)
    presences = ucc_chat.Presence.syncDiff(presences, diff)
    render(presences)
  })

  chan.join()
    .receive("ok", resp => {
      console.log('Joined system channel successfully', resp)
      ucc_chat.handleOnLine()
    })
    .receive("error", resp => {
      console.error('Unable to join system channel', resp)
      ucc_chat.handleOffLine()
    })
  ucc_chat.systemchan = chan
  // return chan;
})
