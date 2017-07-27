import * as cc from "./chat_channel"
import hljs from "highlight.js"

const debug = true;

window.UccChat.on_load(function(ucc_chat) {
  ucc_chat.Messages = Messages
})

class Messages {
  constructor() {
  }

  static new_message(msg) {
    let html = msg.html
    let ucc_chat = window.UccChat
    let ucxchat = ucc_chat.ucxchat

    let at_bottom = ucc_chat.roomManager.at_bottom
    if (debug) console.log('new_message', msg)
    $('.messages-box .wrapper > ul').append(html)

    let last = $(`#${msg.id} .body`)
    if (last.text().trim() == "") {
      last.find('img.emojione').addClass('big')
    }

    $('.messages-box').children('.wrapper').children('ul').children(':last-child').find('pre').each(function(i, block) {
      console.log('block', block)
      hljs.highlightBlock(block)
    })

    if (ucxchat.user_id == msg.user_id) {
      if (debug) { console.log('adding own to', msg.id, $('#' + msg.id)) }
      $('#' + msg.id).addClass("own")
      ucc_chat.main.run(ucc_chat)
    }
    ucc_chat.main.update_mentions(ucc_chat, msg.id)

    if (at_bottom || msg.user_id == ucxchat.user_id) {
      ucc_chat.utils.scroll_bottom()
    }

    ucc_chat.roomManager.new_message(msg.id, msg.user_id)
  }
  static update_message(msg) {
    $('#' + msg.id).replaceWith(msg.html)
      .find('pre').each(function(i, block) {
        hljs.highlightBlock(block)
      })

    if (ucxchat.user_id == msg.user_id) {
      $('#' + msg.id).addClass("own")
    }
  }
  static scroll_bottom() {
    let mypanel = $('.messages-box .wrapper')
    myPanel.scrollTop(myPanel[0].scrollHeight - myPanel.height());
  }

  static send_message(msg) {
    let ucc_chat = window.UccChat
    let ucxchat = ucc_chat.ucxchat
    let user = ucxchat.user_id
    if (msg.update) {
      cc.put("/messages/" + msg.update, {message: msg.value.trim(), user_id: user})
        .receive("ok", resp => {
          $('.message-form-text').removeClass('editing')
          if (resp.html) {
            $('.messages-box .wrapper > ul').append(resp.html)
            $('.messages-box').children('.wrapper').children('ul').children(':last-child').find('pre').each(function(i, block) {
              hljs.highlightBlock(block)
            })
            ucc_chat.utils.scroll_bottom()
            // console.log('got response from send message')
          }
        })
        .receive("error", resp => {
          let error = resp.error
          if (!error) {
            error = "Problem editing message"
          }
          toastr.error(error)
          $('.message-form-text').removeClass('editing')
        })

    } else if (msg.startsWith('/')) {
      let match = msg.match(/^\/([^\s]+)(.*)/)
      let route = "/slashcommand/" + match[1]
      cc.put(route, {args: match[2].trim()})
        .receive("ok", resp => {
          // console.log('slash command resp', resp )
          if (resp.html) {
            $('.messages-box .wrapper > ul').append(resp.html)
            ucc_chat.utils.scroll_bottom()
          }
        })

      ucc_chat.roomManager.remove_unread()

    } else if (!ucc_chat.utils.empty_string(msg.trim())) {
      cc.post("/messages", {message: msg.trim(), user_id: user})
        .receive("ok", resp => {
          if (resp.html) {
            $('.messages-box .wrapper > ul').append(resp.html)
            $('.messages-box').children('.wrapper').children('ul').children(':last-child').find('pre').each(function(i, block) {
              hljs.highlightBlock(block)
            })
            Messages.scroll_bottom()
          }
        })

      ucc_chat.roomManager.remove_unread()
    }

    $('.message-form-text').val('')
  }
}
export default Messages;
