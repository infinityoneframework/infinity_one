// require('./chat_tooltip')
console.log('loading reaction');

$(document).ready(() => {
  $('body').on('click', '.reactions li.selected', e => {
    let emoji = ":" + $(e.currentTarget).data('emoji') + ":"
    let message_id = $(e.currentTarget).closest('li.message').attr('id')
    select(emoji, message_id)
  })
  // .on('click', '.reactions li.add-reaction', e => {
  //   // console.log('reaction e', $(e.currentTarget).offset())
  //   // let message_id = $(e.currentTarget).closest('li.message').attr('id')
  //   // chat_emoji.open_reactions(e.currentTarget, message_id)
  // })
  .on('mouseenter','.reactions > li:not(.add-reaction)', (event) => {
    event.preventDefault()
    event.stopPropagation();
    OneChat.tooltip.showElement($(event.currentTarget).find('.people').get(0), event.currentTarget);
  })

  .on('mouseleave', '.reactions > li:not(.add-reaction)', (event) => {
    event.preventDefault()
    event.stopPropagation();
    OneChat.tooltip.hide();
  })
})

export function select(emoji, message_id) {
  OneChat.tooltip.hide();
  chat_emoji.update_recent(emoji)
  OneChat.userchan.push('reaction:select', {reaction: emoji, message_id: message_id})
}
