console.log('loading chan_wiki.js');

function to_map(element) {
  var ret = {}
  if (element) {
    let attributes = element.attributes;
    let keys = Object.keys(attributes)
    for (var i = 0; i < keys.length; i++) {
      let key = keys[i]
      ret[attributes[key].name] = attributes[key].value
    }
  }
  return ret
}

OneChat.on_connect(function(one_chat, socket) {
  console.log('wikichan connect');
  let ucxchat = one_chat.ucxchat;
  let chan = window.Rebel.channels.wiki.channel;

  one_chat.wikichan = chan;
});
