console.log('loading chan_system.js');

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
    for (var i = 0; i < elem.length; i++) {
      var el = elem[i];
      el.className = el.className.replace(/status-([a-z]+)/, 'status-' + status);
    }
  }
}

let onLine = true;

const offlineContent = `
  <div class="alert alert-warning text-center" role="alert">
    <strong>
      <span class="glyphicon glyphicon-warning-sign"></span>
      Waiting for server connection,
    </stong>
    <a href="/" class="alert-link">Try now</a>
  </div>`

function handleOffLine() {
  if (onLine) {
    $('.connection-status').html('').append(offlineContent).removeClass('status-online')
    $('.flex-tab-bar .tab-button.active').removeClass('active')
    $('.flex-tab-container.opened').removeClass('opened')
    onLine = false
  }
}
function handleOnLine() {
  if (!onLine) {
    onLine = true
    window.location.reload()
    $('.connection-status').html('').addClass('status-online')
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
      update_presence(document.querySelectorAll(`[data-status-name="${presence.username}"]`), status)
      // update_presence($(`[data-status-name="${presence.username}"]`), status)
    })
}

UccChat.on_connect(function(ucc_chat, socket) {
  let ucxchat = ucc_chat.ucxchat
  let chan = socket.channel(ucc_chat.chan_system, {user: ucxchat.username, channel_id: ucxchat.channel_id})

  console.log('chan_system connect')

  // onLine = false;

  handleOnLine()

  socket.onError( () => {
    console.log('!! Socket error')
    handleOffLine()
    onLine = false
  })
  socket.onClose( () => {
    console.log('!! Socket close')
    handleOffLine()
    onLine = false
  })

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
