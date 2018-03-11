import * as cc from "./chat_channel"
import hljs from "highlight.js"

const debug = true;

window.hljs = hljs;
console.log('loading messages');

window.OneChat.on_load(function(one_chat) {
  one_chat.Messages = Messages
})

class Messages {
  constructor() {
  }

  static new_message(msg) {
    // TODO: I'm not sure that this code is still used. Check and remove.
    let html = msg.html
    let one_chat = window.OneChat
    let ucxchat = one_chat.ucxchat

    let at_bottom = one_chat.roomManager.at_bottom

    console.log('new message', msg);

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
      one_chat.main.run(one_chat)
    }
    one_chat.main.update_mentions(one_chat, msg.id)

    if (at_bottom || msg.user_id == ucxchat.user_id) {
      OneUtils.scroll_bottom()
    }

    Rebel.set_event_handlers('[id="' + msg.id + '"]');
    one_chat.roomManager.new_message(msg.id, msg.user_id)
  }
  static update_message(msg) {
    $('#' + msg.id).replaceWith(msg.html)
      .find('pre').each(function(i, block) {
        hljs.highlightBlock(block)
      })

    if (ucxchat.user_id == msg.user_id) {
      $('#' + msg.id).addClass("own")
    }
    Rebel.set_event_handlers('[id="' + msg.id + '"]');
  }
  static scroll_bottom() {
    let mypanel = $('.messages-box .wrapper')
    myPanel.scrollTop(myPanel[0].scrollHeight - myPanel.height());
  }

  static send_message(msg) {
    let one_chat = window.OneChat
    let ucxchat = one_chat.ucxchat
    let user = ucxchat.user_id
    if (msg.update) {
      cc.put("/messages/" + msg.update, {message: msg.value.trim(), user_id: user})
        .receive("ok", resp => {
          $('.message-form-text').removeClass('editing')
          if (resp.html) {
            console.log('resp', resp);
            // Rebel.set_event_handlers('[id="' + msg.id + '"]');
            $('.messages-box .wrapper > ul').append(resp.html)
            //Rebel.set_event_handlers('[id="' + msg.id + '"]');
            $('.messages-box').children('.wrapper').children('ul').children(':last-child').find('pre').each(function(i, block) {
              hljs.highlightBlock(block)
            })
            OneUtils.scroll_bottom()
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
            OneUtils.scroll_bottom()
          }
        })

      one_chat.roomManager.remove_unread()

    } else if (!OneUtils.empty_string(msg.trim())) {
      cc.post("/messages", {message: msg.trim(), user_id: user})
        .receive("ok", resp => {
          if (resp.html) {
            $('.messages-box .wrapper > ul').append(resp.html)
            console.log('resp', resp);
            // Rebel.set_event_handlers('[id="' + msg.id + '"]');
            $('.messages-box').children('.wrapper').children('ul').children(':last-child').find('pre').each(function(i, block) {
              hljs.highlightBlock(block)
            })
            Messages.scroll_bottom()
          }
        })

      one_chat.roomManager.remove_unread()
    }

    $('.message-form-text').val('')
  }
}
export default Messages;
