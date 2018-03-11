(function(){
  console.log('loading main');

  var Main = {
    run: function(one_chat) {
      this.update_mentions(one_chat)
    // update_flexbar()
      one_chat.roomManager.updateMentionsMarksOfRoom()
    },
    update_mentions: function(one_chat, id) {
      // let username = one_chat.ucxchat.username;
      // let selector = `.mention-link[data-username="${username}"]`
      // if (id)
      //   selector = '#' + id + ' ' + selector

      // $(selector).addClass('mention-link-me background-primary-action-color')
    }
  }

  window.mentions = Main.update_mentions
  window.OneChat.main = Main
})();

