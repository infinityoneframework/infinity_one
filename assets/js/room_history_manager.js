import * as cc from "./chat_channel"
import * as main from "./main"

const start_conversation = `<li class="start color-info-font-color">${gettext.start_of_conversation}</li>`
const container = '.messages-box .wrapper ul'
const wrapper = '.messages-box .wrapper'
const debug = true
console.log('loading room_history_manager');

UccChat.on_load(function(ucc_chat) {
  ucc_chat.roomHistoryManager = new RoomHistoryManager(ucc_chat)
})

class RoomHistoryManager {
  constructor(ucc_chat) {
    this.ucc_chat = ucc_chat;
    this.is_loading = true;
    this.scroll_pos = {};
    this.current_room = undefined;
    this.scroll_window = undefined;
    this.scroll_to = ucc_chat.scroll_to;
    this.page = this.pagination();

    setInterval(e => {
      this.update_scroll_pos();
    }, 1000);
  }

  get isLoading()   { return this.is_loading; }

  pagination() {
    let pagination = $('.messages-box .pagination');
    let page = {};

    page.page_number = page.first_page = page.last_page = pagination.data('page-number');
    page.page_size = pagination.data('page-size');
    page.total_pages = pagination.data('total-pages');

    return page;
  }

  pagination_prev(pagination) {
    let page = this.page;

    page.page_number = page.first_page = pagination.page_number;
    page.page_size = pagination.page_size;
    page.total_pages = pagination.total_pages;

    return page;
  }

  pagination_next(pagination) {
    let page = this.page;

    page.page_number = page.last_page = pagination.page_number;

    page.page_size = pagination.page_size;
    page.total_pages = pagination.total_pages;

    return page;
  }

  pagination_set(pagination) {
    let page = {};

    page.page_number = page.last_page = page.first_page = pagination.page_number;
    page.page_size = pagination.page_size;
    page.total_pages = pagination.total_pages;

    return page;
  }

  hasMorePrev() {
    return this.page.first_page > 1;
  }

  hasMoreNext() {
    return this.page.last_page < this.page.total_pages;
  }

  get_bottom_message() {
    let list = $(container + ' li[id]');
    let box = $(wrapper)[0].getBoundingClientRect();
    let found = list[list.length - 1];
    list.each((i, item) => {
      let msg_box = item.getBoundingClientRect();
      if (msg_box.bottom == box.bottom || msg_box.top < box.bottom && msg_box.bottom > box.bottom) {
        found = item;
      }
    });
    return found;
  }

  scroll_to_message(ts) {
    if (debug) { console.log('scroll_to_message', ts); }
    let target = $('.messages-box li[data-timestamp="' + ts + '"]');

    if (target.offset()) {
      this.scroll_to(target);
    }
  }

  fix_new_days() {
    if (debug) { console.log('fix_new_days'); }

    let list = $(container + ' li[id]');
    let last = list.length - 1;

    for (let i = 0; i < last - 1; i++) {
      let item = list[i];
      if ($(item).hasClass('new-day') && i > 0) {
        if ($(item).data('date') == $(list[i - 1]).data('date')) {
          $('#' + $(item).attr('id')).removeClass('new-day');
        }
      }
    }
    this.fix_top_message();
  }

  fix_top_message() {
    let list = $(container + ' li[id]');
    $(list[0]).removeClass('sequential').addClass('new-day');
  }

  cache_room() {
    if (ucxchat.channel_id) {
      this.cached_scrollTop = $(wrapper)[0].scrollTop;
    }
  }

  restore_cached_room() {
    if (ucxchat.channel_id) {
      $(wrapper)[0].scrollTop = this.cached_scrollTop;
      UccChat.roomManager.bind_history_manager_scroll_event();
    }
  }

  get getMorePrev() {
    if (debug) { console.log('roomHistoryManager.getMorePrev()'); }

    this.is_loading = true;
    UccUtils.add_page_animation_styles();
    this.startLoadMorePrevAnimation();

    let html = $('.messages-box .wrapper ul').html();
    let first_id = $('.messages-box .wrapper ul li[id]').first().attr('id');
    let page = {
      page: this.page.first_page - 1,
      page_size: this.page.page_size
    };

    cc.get('/messages', {page: page})
      .receive("ok", resp => {
        if (debug) { console.log('got response back from loading', resp); }

        let has_more = this.loadMoreAnimation();

        $(container)[0].innerHTML = has_more + resp.html + html;

        if (debug) { console.log('finished loading', first_id); }

        this.scroll_to($('#' + first_id), -80);

        this.fix_new_days();

        this.removeLoadMoreAnimation();

        if (this.page.page_number == 1) {
          $(container).children().first().addClass('new-day');
          $(container).prepend(start_conversation);
        }

        this.page = this.pagination_prev(resp.page);

        UccUtils.remove_page_loading();
        this.removeLoadMoreAnimation();
        this.add_jump_recent();
        this.is_loading = false;
        this.ucc_chat.main.run(this.ucc_chat);
        Rebel.set_event_handlers(container);
      });
  }
  get getMoreNext() {

    UccUtils.add_page_animation_styles();
    this.startLoadMoreNextAnimation();
    this.is_loading = true;

    let html = $(container).html();
    let ts = $('.messages-box li[data-timestamp]').last().data('timestamp');
    let last_id = $('.messages-box li[data-timestamp]').last().attr('id');

    let page = {
      page: this.page.page_number + 1,
      page_size: this.page.page_size
    };

    cc.get('/messages/previous', {page: page, timestamp: ts})
      .receive("ok", resp => {
        if (debug) { console.log('getMoreNext resp', resp); }

        $('.messages-box .wrapper ul')[0].innerHTML = html + resp.html;

        this.scroll_to($('#' + last_id), 0);

        this.page = this.pagination_next(resp.page);
        UccUtils.remove_page_loading();
        this.removeLoadMoreAnimation();
        this.add_jump_recent();
        this.is_loading = false;
        this.ucc_chat.main.run(this.ucc_chat);
        Rebel.set_event_handlers(container);
      })
  }

  getLastMessages() {
    if (debug) { console.log("getLastMessages"); }

    UccUtils.add_page_animation_styles();
    this.startLoadMoreNextAnimation();
    this.is_loading = true;

    $('.messages-box .wrapper ul li.load-more').html(UccUtils.loading_animation());
    let page = {
      page: this.page.page_size,
      page_size: this.page.page_size
    }
    cc.get('/messages', {page: page})
      .receive("ok", resp => {
        $(container)[0].innerHTML = resp.html;

        UccUtils.scroll_bottom();

        UccUtils.remove_page_loading();
        this.removeLoadMoreAnimation();
        this.page = this.pagination_set(resp.page);
        this.add_jump_recent();
        this.is_loading = false;
        this.ucc_chat.main.run(this.ucc_chat);
        Rebel.set_event_handlers(container);
      })
  }

  getSurroundingMessages(timestamp) {
    if (debug) { console.log("jump-to need to load some messages", timestamp); }

    this.is_loading = true;
    UccUtils.page_loading();
    $('.messages-box .wrapper ul li.load-more').html(UccUtils.loading_animation());
    cc.get('/messages/surrounding', {page: this.page, timestamp: timestamp})
      .receive("ok", resp => {
        $(container)[0].innerHTML = resp.html;

        let message_id = $(`.messages-box li[data-timestamp="${timestamp}"]`).attr('id');

        if (message_id) {
          this.scroll_to($('#' + message_id), -200);
        }

        UccUtils.remove_page_loading();
        this.page = this.pagination_set(resp.page);
        this.add_jump_recent();
        this.is_loading = false;
        this.ucc_chat.main.run(this.ucc_chat);
        Rebel.set_event_handlers(container);
      })
  }

  new_room(room) {
    if (debug) { console.log('new_room', room); }
    this.current_room = room;
    this.is_loading = false;
    this.page = this.pagination();
  }

  scroll_new_window() {
    this.is_loading = true;
    this.scroll_window = $(wrapper)[0];

    if (!this.scroll_pos[this.current_room]) {
      // console.log('scroll_new_window this.current_room', this.current_room)
      this.ucc_chat.userchan.push("get:currentMessage", {room: this.current_room})
        .receive("ok", resp => {
          if (debug) { console.warn('scroll_new_window ok resp', resp); }
          this.set_scroll_top("ok", resp);
        })
        .receive("error", resp => {
          // console.warn('scroll_new_window err resp', resp)
          //UccUtils.remove_page_loading()
          this.set_scroll_top("error", resp)
        })
    } else {
      // console.warn('scroll_new_window else this', this)
      // UccUtils.remove_page_loading()
      this.set_scroll_top("ok", {value: this.scroll_pos[this.current_room]});
    }

    this.add_jump_recent()
    this.fix_top_message()

    // I don't like this approach, but not sure how else to get around
    // the debounce timer on the scroll event handler.
    setTimeout(function() {
      if (UccUtils.is_scroll_bottom()) {
        // allow the scroll event handler to detect direction
        UccUtils.scroll_down(1);
      } else if (UccUtils.is_scroll_top()) {
        // allow the scroll event handler to detect direction
        UccUtils.scroll_up(1);
      }
      UccChat.roomHistoryManager.is_loading = false;
      $('.page-loading-container .loading-animation').remove();
      // console.log('scroll new window timeout')
    }, 1000);
  }

  add_jump_recent() {
    if (debug) { console.log('add_jump_recent', this.hasMoreNext()); }
    if (this.hasMoreNext()) {
      $('.jump-recent').removeClass('not');
    } else {
      $('.jump-recent').addClass('not');
    }

    if (this.hasMorePrev() && UccUtils.is_scroll_top() && UccUtils.is_scroll_bottom()) {
      $('.jump-previous').removeClass('not');
    } else {
      $('.jump-previous').addClass('not');
    }
  }

  set_scroll_top(code, resp) {
    if (resp.value == "") {
      let elem = $(container);
      // console.log('set_scroll_top 1 value', resp, elem, elem.parent().scrollTop())
      UccUtils.scroll_bottom();
    } else {
      if (debug) { console.log('set_scroll_top 2 value', resp); }

      if (code == "ok") {
        // console.log('fond code ok')
        this.scroll_to_message(resp.value);
      } else {
        // console.log('code not ok', code)
        UccUtils.scroll_bottom();
      }
    }
  }

  update_scroll_pos() {
    if (!this.is_loading && this.scroll_window && $(wrapper).length > 0) {
      let current_message = this.bottom_message_ts();

      if ((current_message != this.scroll_pos[this.current_room])) {
        this.scroll_pos[this.current_room] = current_message;

        if (current_message && current_message != "") {
          this.ucc_chat.userchan.push("update:currentMessage", {value: current_message});
        }
      }
    }
  }

  bottom_message_ts() {
    let cm = this.get_bottom_message();
    if (cm) {
      return cm.getAttribute('data-timestamp');
    }
  }

  loadMoreAnimation() {
    return `<li class='load-more'>${UccUtils.loading_animation()}</li>`;
  }

  startLoadMorePrevAnimation() {
    if (debug) { console.log('startLoadMoreAnimation'); }
    $('.messages-box .wrapper ul').prepend(this.loadMoreAnimation());
  }

  startLoadMoreNextAnimation() {
    if (debug) { console.log('startLoadMoreNextAnimation'); }

    this.removeLoadMoreAnimation();
    $('.messages-box .wrapper ul').append(this.loadMoreAnimation());
  }

  removeLoadMoreAnimation() {
    if (debug) { console.log('removeGetMoreAnimation'); }
    $('.messages-box .wrapper ul li.load-more').remove();
  }
}

export default RoomHistoryManager

