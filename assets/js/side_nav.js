import * as cc from './chat_channel'
console.log('loading side_nav');

UccChat.on_load(function(ucc_chat) {
  ucc_chat.sideNav = new SideNav(ucc_chat)
})

class SideNav {
  constructor(ucc_chat) {
    this.ucc_chat = ucc_chat
    this.register_events()
  }

  get userchan() { return this.ucc_chat.userchan }
  get systemchan() { return this.ucc_chat.systemchan }
  get roomManager() { return this.ucc_chat.roomManager }
  get roomHistoryManager() {return this.ucc_chat.roomHistoryManager }
  get navMenu() { return this.ucc_chat.navMenu }
  get notifier() { return this.ucc_chat.notifier }

  // more_channels() {
  //   // console.log('cliecked more channels')
  //   this.userchan.push('side_nav:more_channels')
  //     .receive("ok", resp => {
  //        $('.flex-nav section').html(resp.html).parent().removeClass('animated-hidden')
  //        $('.arrow').toggleClass('close', 'bottom')
  //     })
  // }
  more_users() {
    // console.log('cliecked more channels')
    this.userchan.push('side_nav:more_users')
      .receive("ok", resp => {
         $('.flex-nav section').html(resp.html).parent().removeClass('animated-hidden')
         $('.arrow').toggleClass('close', 'bottom')
      })
  }
  channel_link_click(elem) {
    let name = elem.attr('href').replace('/channels/', '')
    // console.log('channel link click', name)
    this.roomManager.open_room(name, name, function() {
      $('.flex-nav').addClass('animated-hidden')
      $('.arrow').toggleClass('close', 'bottom')
    })
  }
  bind_scroll_event() {
    $('.rooms-list').bind('scroll', _.throttle((e) => {
      let list = $('.rooms-list')
      if (!list) return

      let listOffset = list.offset()
      let listHeight = list.height()

      let showTop = false
      let showBottom = false
      $('li.has-alert').each((i,item) => {
        // console.log('item', item)
        if ($(item).offset().top < listOffset.top - $(item).height() + 20)
          showTop = true

        if ($(item).offset().top > listOffset.top + listHeight - 20)
          showBottom = true
      })
      if (showTop) {
        $('.top-unread-rooms').removeClass('hidden')
      } else {
        $('.top-unread-rooms').addClass('hidden')
      }

      if (showBottom) {
        $('.bottom-unread-rooms').removeClass('hidden')
      } else {
        $('.bottom-unread-rooms').addClass('hidden')
      }
    }, 200))
  }

  set_nav_top_icon(icon) {
    // console.log('set_nav_top_icon', icon)
    $('aside.side-nav span.arrow')
      .removeClass('top')
      .removeClass('bottom')
      .removeClass('close')
      .addClass(icon)
  }

  register_events() {

    this.bind_scroll_event()
    $('body')
    .on('click', 'button.test-notifications', e => {
      e.preventDefault()
      this.notifier.desktop('Desktop Notification Test', 'This is a desktop notification.', {duration: 5})
      // console.log('test notifications')
      return false
    })
    .on('change', '#account_new_room_notification', e => {
      let sound = $(e.currentTarget).val()
      if (sound != 'none' && sound != "system_default")
        $('#' + sound)[0].play()
    })
    .on('change', '#account_new_message_notification', e => {
      let sound = $(e.currentTarget).val()
      if (sound != 'none' && sound != "system_default")
        $('#' + sound)[0].play()
    })
    .on('click', 'span.arrow', (e) => {
      // console.log('span.arrow click', e.currentTarget)
      if ($(e.currentTarget).hasClass('close')) {
        $('.flex-nav header').click()
        this.set_nav_top_icon('bottom')
      } else {
        $('.side-nav .account-box').click()
      }
      e.preventDefault()
      return false
    })
    .on('click', '.side-nav .account-box', (e) => {
      e.preventDefault()
      let elem = $('aside.side-nav span.arrow')
      // console.log('.side-nav .account-box click', elem)
      if (elem.hasClass('top')) {
        this.set_nav_top_icon('bottom')
        SideNav.hide_account_box_menu()
      } else if (elem.hasClass('bottom')) {
        this.set_nav_top_icon('top')
        SideNav.show_account_box_menu()
      }
    })
    .on('click', 'button#logout', (e) => {
      e.preventDefault()
      window.location.href = "/logout"
    })
    .on('click', 'button.account-link', (e) => {
      e.preventDefault()
      this.roomHistoryManager.cache_room()
      $('.main-content-cache').html($('.main-content').html())
      this.userchan.push('side_nav:open', {page: $(e.currentTarget).attr('id')})
        .receive("ok", resp => {
          console.log('resp', resp)
          $('.flex-nav section').html(resp.html)
          console.log('resp from side_nav:open')
          this.navMenu.open()
          $('.flex-nav .wrapper ul li').first().addClass('active');
        })
      $('div.flex-nav').removeClass('animated-hidden')
      this.set_nav_top_icon('close')
    })
    // .on('click', 'nav.options button.status', (e) =>  {
    //   e.preventDefault()
    //   this.systemchan.push('status:set:' + $(e.currentTarget).data('status'), {})
    // })
    .on('click', '.flex-nav header', (e) => {
      console.log('.flex-nav header click', e)
      e.preventDefault()
      this.userchan.push('side_nav:close', {})
      // console.log('.flex-nav header clicked')
      $('div.flex-nav').addClass('animated-hidden')
      this.set_nav_top_icon('bottom')
      console.log('going to restore cache')
      if ($('.main-content-cache').html() != '') {
        console.log('restoring cache now!')
        $('.main-content').html($('.main-content-cache').html())
        $('.main-content-cache').html('')
        this.roomHistoryManager.restore_cached_room()
        window.Rebel.set_event_handlers('body')
      }
      SideNav.hide_account_box_menu()
    })
    .on('click', '.account-link', e => {
      console.log('account link click')
      e.preventDefault()
      $('.flex-nav .wrapper li').removeClass('active');
      $(e.currentTarget).parent().addClass('active');
      this.userchan.push('account_link:click:' + $(e.currentTarget).data('link'), {})
      this.navMenu.close()
    })
    // .on('click', '.admin-link', e => {
    //   console.log('admin link click')
    //   e.preventDefault()
    //   this.userchan.push('admin_link:click:' + $(e.currentTarget).data('link'), {})
    //   navMenu.close()
    // })
    .on('submit', '#account-preferences-form', e => {
      e.preventDefault()
      this.userchan.push('account:preferences:save', $(e.currentTarget).serializeArray())
        .receive("ok", resp => {
          if (resp.success) {
            toastr.success(resp.success)
          } else if (resp.error) {
            toastr.error(resp.error)
          }
        })
    })
    .on('submit', '#account-profile-form', e => {
      e.preventDefault()
      this.userchan.push('account:profile:save', $(e.currentTarget).serializeArray())
        .receive("ok", resp => {
          if (resp.success) {
            toastr.success(resp.success)
          } else if (resp.error) {
            toastr.error(resp.error)
          }
        })
    })
    // .on('click', 'button.more-channels', e =>  {
    //   e.preventDefault()
    //   this.more_channels()
    //   return false
    // })
    .on('click', 'button.more-users', e =>  {
      e.preventDefault()
      this.more_users()
      return false
    })
    .on('click', 'a.channel-link', e => {
      console.log('a.channel-link click', e)
      e.preventDefault()
      this.channel_link_click($(e.currentTarget))
      return false
    })
    // $('button.status').on('click', function(e) {
    //   console.log('clicked status change', $(this).data('status'))
    // })
  }
  static show_account_box_menu() {
    console.log('show_account_box_menu')
    $('.account-box').addClass('active')
    $('.account-box nav.options').removeClass('animated-hidden')
  }

  static hide_account_box_menu() {
    console.log('hide_account_box_menu')
    $('.account-box').removeClass('active')
    $('.account-box nav.options').addClass('animated-hidden')
  }
}

export default SideNav;
