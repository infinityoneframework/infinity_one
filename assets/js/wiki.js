console.log('loading wiki');

class Wiki {
  constructor(one_chat) {
    this.registerEvents();
    this.one_chat = one_chat;
  }

  openStaticPage() {
    if ($('#flex-tabs').hasClass('static-pages') === false) {
      $('#flex-tabs').addClass('static-pages');
      // copy current contents to stash
      $('#flex-tab-cache').html($('#flex-tabs').html());
    }
  }

  restoreChannelFlexTax() {
    let $flexTabs = $('#flex-tabs');
    if ($flexTabs.hasClass('static-pages')) {
      if ($flexTabs.hasClass('opened')) {
        $flexTabs.removeClass('opened');
      }
      $flexTabs.removeClass('static-pages').html($('#flex-tab-cache').html());
      Rebel.set_event_handlers('#flex-tabs');
    }
    $('.page-container.page-home.page-static').remove();
    $('.page-link').removeClass('active');
  }

  registerEvents() {
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
      let local = $(e.currentTarget).attr('href').match(/^\/wiki\/(.*)$/);

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
  }
}

OneChat.on_load(function(one_chat) {
  one_chat.Wiki = new Wiki(one_chat);
});
