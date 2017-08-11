(function() {
  UccChat.on_connect(function(ucc_chat, socket) {
    console.log('chan_mscs.js onconnect', ucc_chat);
    let ucxchat = ucc_chat.ucxchat
    let chan = Rebel.channels.mscs.channel;
    // Handle updating the 3 display lines
    chan.on("display:line", msg => {
      // if (ucc_chat.debug) console.log("update:line: ", msg)
      console.error("update:line: ", msg)
      let line = $('.disp-'+msg.key)
      if (msg.highlight) {
        line.html(msg.text).addClass("text-highlight")
      }
      else {
        line.html(msg.text).removeClass("text-highlight")
      }
    })

  });
})();
