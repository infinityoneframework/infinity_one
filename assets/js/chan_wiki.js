console.log('loading chan_wiki.js');

OneChat.on_connect(function(one_chat, socket) {
  console.log('wikichan connect');
  let ucxchat = one_chat.ucxchat;
  let chan = window.Rebel.channels.wiki.channel;

  one_chat.wikichan = chan;
});

