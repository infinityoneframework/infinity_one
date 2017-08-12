//
// Copyright @E-MetroTel 2015-2016
//

//////////
// Public functions

(function() {
  console.log('loading mscs_watchdog')

  var Watchdog = {
    wd_timer_ref: null,
    wd_timer:  0,
    wd_message_toggle_timeout: 3000,
    wd_message_toggle_message: 0,
    offline_msg_timer_ref: null,
    client_disconnected: false,
    start_watchdog: function(timer) {
      this.wd_timer = timer
      start_watchdog_timer(this)
    },
    cancel_watchdog: function() {
      cancel_watchdog_timer(this)
      this.client_disconnected = false
    },
    stop_server_connecting_message: function() {
      this.client_disconnected = false
      clear_offline_msg_timer(this)
    },
    start_server_connecting_message: function() {
      this.client_disconnected = false     // force clear screen
      this.wd_message_toggle_message = 0
      display_server_offline_msg(this)
      this.client_disconnected = true
      display_server_connecting_message(this)
    }
  }
  window.Mscs.Watchdog = Watchdog;
})();

//////////
// Private functions

function cancel_watchdog_timer(wd) {
  if (wd.wd_timer_ref != null){
    clearTimeout(wd.wd_timer_ref)
    wd.wd_timer_ref = null
  }
}

function start_watchdog_timer(wd) {
  cancel_watchdog_timer(wd)
  if (wd.wd_timer > 0)
    wd.wd_timer_ref = setTimeout(watchdog_timeout, wd.wd_timer, wd)
}

function watchdog_timeout(wd) {
  console.warn("watchdog timeout")
  wd.client_disconnected = false
  display_server_offline_msg(wd)
}

function clear_offline_msg_timer(wd) {
  if (wd.offline_msg_timer_ref != null)
    clearTimeout(wd.offline_msg_timer_ref)
}
function start_offline_msg_timer(wd) {
  clear_offline_msg_timer(wd)
  wd.offline_msg_timer_ref = setTimeout(display_server_connecting_message, wd.wd_message_toggle_timeout, wd)
}
function display_server_offline_msg(wd) {
  if (wd.client_disconnected == false)
    clear_all_display_labels_icons(wd)
}
function display_server_connecting_message(wd) {
  if (wd.client_disconnected == true)
  {
    if (wd.wd_message_toggle_message == 0)
    {
      wd.wd_message_toggle_message = 1
      $(".display-container .line-0 .display-line").html("Connecting to S1...")
    }
    else
    {
      wd.wd_message_toggle_message = 0
      $(".display-container .line-0 .display-line").html("Server Unreachable")
    }
    start_offline_msg_timer(wd)
  }
}

function clear_all_display_labels_icons(wd) {
  $('.display-container .display-line').html("&nbsp;")
  $('.display-container .context').html("&nbsp;")
  $('.display-container .icon-field').addClass('transparent')
  $('.softkeys-container .buttn .label').html("&nbsp;")
  $('.pk-strip .pk').attr("class", "pk")
  $('.pk-strip .pk .label').text("&nbsp;")
}

