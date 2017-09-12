(function() {
  console.log('utils.js loading...')
  const debug = false;

  const item_selector = '.popup-item';
  const selected_selector = item_selector + '.selected';

  var Utils = {
    remove: function(arr, item) {
      if (debug) { console.log('remove', arr, item) }

      for(var i = arr.length; i--;) {
          if(arr[i] === item) {
              arr.splice(i, 1);
          }
      }
    },
    debounce: function(func, wait, immediate) {
      // Taken from: https://davidwalsh.name/javascript-debounce-function
      //
      // Returns a function, that, as long as it continues to be invoked, will not
      // be triggered. The function will be called after it stops being called for
      // N milliseconds. If `immediate` is passed, trigger the function on the
      // leading edge, instead of the trailing.
      //
      // Usage:
      //   var myEfficientFn = debounce(function() {
      //     // All the taxing stuff you do
      //   }, 250);
      //
      //   window.addEventListener('resize', myEfficientFn);
      var timeout;
      return function() {
        var context = this, args = arguments;
        var later = function() {
          timeout = null;
          if (!immediate) func.apply(context, args);
        }
        var callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func.apply(context, args);
      }
    },
    scroll_bottom: function() {
      let elem = $('.messages-box .wrapper')[0]
      if (elem)
        elem.scrollTop = elem.scrollHeight - elem.clientHeight
      else
        console.warn('invalid elem')
    },
    scroll_down: function(height) {
      let elem = $('.messages-box .wrapper')
      if (elem)
        elem.scrollTop(getScrollBottom() + height)
      else
        if (debug) { console.warn('invalid elem') }
    },
    getScrollBottom: function() {
      let elem = $('.messages-box .wrapper')[0]
      if (elem) {
        return elem.scrollHeight - $(elem).innerHeight
      } else {
        if (debug) { console.warn('invalid elem') }
        return 1000
      }
    },
    is_scroll_bottom: function() {
      let elem = $('.messages-box .wrapper')[0]
      if (elem) {
        return elem.scrollTop + $(elem).innerHeight() + 1 >= elem.scrollHeight
      } else {
        if (debug) { console.warn('invalid elem') }
        return true
      }
    },
    empty_string: function(string) {
      return /^\s*$/.test(string)
    },
    loadmore_with_animation: function() {
      let d = document.createElement('li')
      return $(d).addClass('load-more').html(this.loading_animation())
    },
    loadmore: function() {
      return `<li class="load-more"></li>`
    },
    loading_animation: function() {
      return `
        <div class='loading-animation'>
          <div class='bounce1'></div>
          <div class='bounce2'></div>
          <div class='bounce3'></div>
        </div`
    },
    page_loading: function() {
      let stylesheet = `<style>
        #initial-page-loading .loading-animation {
          background: linear-gradient(to top, #6c6c6c 0%, #aaaaaa 100%);
          z-index: 1000;
        }
        .loading-animation {
          top: 0;
          right: 0;
          bottom: 0;
          left: 0;
          display: flex;
          align-items: center;
          position: absolute;
          justify-content: center;
          text-align: center;
          z-index: 100;
        }
        .loading-animation > div {
          width: 10px;
          height: 10px;
          margin: 2px;
          border-radius: 100%;
          display: inline-block;
          background-color: rgba(255,255,255,0.6);
          -webkit-animation: loading-bouncedelay 1.4s infinite ease-in-out both;
          animation: loading-bouncedelay 1.4s infinite ease-in-out both;
        }
        .loading-animation .bounce1 {
          -webkit-animation-delay: -0.32s;
          animation-delay: -0.32s;
        }
        .loading-animation .bounce2 {
          -webkit-animation-delay: -0.16s;
          animation-delay: -0.16s;
        }
        @-webkit-keyframes loading-bouncedelay {
          0%,
          80%,
          100% { -webkit-transform: scale(0) }
          40% { -webkit-transform: scale(1.0) }
        }
        @keyframes loading-bouncedelay {
          0%,
          80%,
          100% { transform: scale(0); }
          40% { transform: scale(1.0); }
        }
        </style>`
     $('head').prepend(stylesheet)
    },
    remove_page_loading: function() {
      $('head > style').remove()
    },
    code_update: function(resp) {
      if (resp.html) {
        $(resp.selector)[resp.action](resp.html)
      } else {
        $(resp.selector)[resp.action]()
      }
      $('.input-message').focus()
    },
    push_history: function() {
      let ucxchat = window.UccChat.ucxchat
      history.pushState(history.state, ucxchat.display_name, '/' + ucxchat.room_route + '/' + ucxchat.display_name)
    },
    replace_history: function() {
      history.replaceState(history.state, ucxchat.display_name, '/' + ucxchat.room_route + '/' + ucxchat.display_name)
    },
    // taken from http://blog.vishalon.net/javascript-getting-and-setting-caret-position-in-textarea
    getCaretPosition: function(ctrl) {
      // IE < 9 Support
      if (document.selection) {
        ctrl.focus();
        var range = document.selection.createRange();
        var rangelen = range.text.length;
        range.moveStart('character', -ctrl.value.length);
        var start = range.text.length - rangeLen;
        return {'start': start, 'end': start + rangeLen};
      }
      // IE >= 9 and other browsers
      else if (ctrl.selectionStart || ctrl.selectionStart == '0') {
        return {'start': ctrl.selectionStart, 'end': ctrl.selectionEnd};
      } else {
        return {'start': 0, 'end': 0}
      }
    },
    // taken from http://blog.vishalon.net/javascript-getting-and-setting-caret-position-in-textarea
    setCaretPosition: function(ctrl, start, end) {
      // IE >= 9 and other browsers
      if (ctrl.setSelectionRange){
        ctrl.focus();
        ctrl.setSelectionRange(start, end)
      }
      // IE < 9
      else if (ctrl.createTextRange) {
        var range = ctrl.createTextRange();
        range.collapse(true);
        range.moveEnd('character', end);
        range.moveStart('character', start);
        range.select();
      }
    },
    downArrow: function() {
      var curr = document.querySelector(selected_selector);
      console.log('arrow down', curr);
      if (!curr) {
        var list = document.querySelector('.message-popup-items');
        if (list) {
          curr = list.firstElementChild;
        }
      }
      if (curr) {
        var next = curr.nextElementSibling;
        console.log('next', next);
        if (next && next.classList) {
          curr.classList.remove('selected');
          next.classList.add('selected');
        }
      }
    },
    upArrow: function() {
      var curr = document.querySelector(selected_selector);
      console.log('up down', curr);
      if (!curr) {
        var list = document.querySelector('.message-popup-items');
        if (list) {
          curr = list.lastElementChild;
        }
      }
      if (curr) {
        var prev = curr.previousElementSibling;
        console.log('prev', prev);
        if (prev && prev.classList) {
          curr.classList.remove('selected');
          prev.classList.add('selected');
        }
      }
    },
    mb_before: function(event) {
      console.log('running mb_before', event)
      if (event.key == "ArrowUp" || event.key == "ArrowDown") {
        event.stopPropagation();
        event.preventDefault();
      }
    }
  }

  window.pl = Utils.page_loading
  window.rpl = Utils.remove_page_loading

  window.UccChat.utils = Utils
 })();
