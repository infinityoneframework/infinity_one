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

$('body')
.on('click', '[data-toggle="tab"]', (e) => {
  let $target = $(e.currentTarget);
  if ($target.hasClass('active')) {
    return;
  }
  let $tablist = $target.closest('[role="tablist"]');
  let contentId = $tablist.attr('id') + 'Content';
  let tabId = $target.attr('id').replace(/\-tab$/, '');

  $(`#${contentId} .active[role="tabpanel"]`).removeClass('active show');
  $(`#${contentId}`).find(`#${tabId}`).addClass('active show');
  $tablist.find('[role="tab"]').removeClass('active').attr('aria-selected', 'false');
  $target.addClass('active').attr('aria-selected', 'true');
})
.on('click', 'a[href]', e => {
  console.log('e', e);
  let local = $(e.currentTarget).attr('href').match(/^\/wiki\/(.*)$/);
  console.log('local href', local);

  if (local) {
    e.preventDefault();
    e.stopPropagation();
    let params = {title: local[1]}
    if ($(e.currentTarget).hasClass('new-page')) {
      params.new_page = true;
    }
    OneChat.wikichan.push('open_room', params);
  }
})
.on('keyup', '[name="wiki[title]"]', e => {
  $('h2 span.room-title').text($('[name="wiki[title]"]').val());
})
