(function(){
  var Main = {
    run: function(ucc_chat) {
      this.update_mentions(ucc_chat)
    // update_flexbar()
      ucc_chat.roomManager.updateMentionsMarksOfRoom()
    },
    update_mentions: function(ucc_chat, id) {
      let username = ucc_chat.ucxchat.username;
      let selector = `.mention-link[data-username="${username}"]`
      if (id)
        selector = '#' + id + ' ' + selector

      $(selector).addClass('mention-link-me background-primary-action-color')
    }
  }

  window.mentions = Main.update_mentions
  window.UccChat.main = Main
})();

