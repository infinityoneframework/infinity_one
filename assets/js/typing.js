console.log('typing.js loading')

// import * as cc from "./chat_channel"

const debug = false;

window.UccChat.on_load(function(ucc_chat) {
  ucc_chat.typing = new Typing(ucc_chat)
})

class Typing {

  constructor(ucc_chat) {
    this.typing = ucc_chat.typing
    this.timer = undefined
    this.ucc_chat = ucc_chat
    this.ucxchat = ucc_chat.ucxchat
  }

  get is_typing() { return this.typing; }
  set is_typing(val) { this.typing = val; }

  get timer_ref() { this.timer }
  set timer_ref(val) { this.timer = val }

  clear() {
    this.is_typing = false
    clearTimeout(this.timer_ref)
    this.timer_ref = undefined
  }

  start_typing() {
    if (!this.is_typing) {
      this.is_typing = true
      this.timer_ref = setTimeout(this.typing_timer_timeout, 15000, this, this.ucxchat.channel_id, this.ucxchat.user_id)
      // cc.post("/typing")
    }
  }
  update_typing(typing) {
    if (debug) { console.log('Typing.update_typing', typing) }
    let ucxchat = this.ucxchat

    if (typing.indexOf(ucxchat.username) < 0) {
      this.do_update_typing(false, typing)
    } else {
      ucc_chat.utils.remove(typing, ucxchat.username)
      this.do_update_typing(true, typing)
    }
  }

  do_update_typing(self_typing, list) {
    if (debug) { console.log('to_update_typing', self_typing, list) }
    let len = list.length
    let prepend = ""
    if (len > 1) {
      if (self_typing) {
        prepend = " " + gettext.are_also_typing
      } else {
        prepend = " " + gettext.are_typing
      }
    } else if (len == 0) {
      $('form.message-form .users-typing').html('')
      return
    } else {
      if (self_typing) {
        prepend = " " + gettext.is_also_typing
      }
      else {
        prepend = " " + gettext.is_typing
      }
    }

    $('form.message-form .users-typing').html("<strong>" + list.join(", ") + "</strong>" + prepend)
  }

  typing_timer_timeout(this_ref, channel_id, user_id) {
    if (debug) { console.log('typing_timer_timeout', this_ref.is_typing) }
    if ($('.message-form-text').val() == '') {
      if (this_ref.is_typing) {
        // assume they cleared the textedit and did not send
        this_ref.is_typing = false
        this_ref.timer_ref = undefined
        this.ucc_chat.roomchan.push("/typing/stop", {ucxchat: {method: "delete"},
          channel_id: channel_id, user_id: user_id, room: this.ucc_chat.ucxchat.room})
      }
    } else {
      this_ref.timer_ref = setTimeout(this.typing_timer_timeout, 15000, this_ref, channel_id, user_id)
    }
  }
}
