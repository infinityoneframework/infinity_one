(function() {
  console.log('loading mscs')
  window.Mscs = {}
  // function isVisible(elem) {
  //   var style = window.getComputedStyle(elem);
  //   return (style.display !== 'none');
  // }
  // function toggle_visible(elem) {
  //   console.log(elem,isVisible(elem))
  //   if (isVisible(elem)) {
  //     elem.style.display = 'none';
  //   } else {
  //     elem.style.display = 'flex';
  //   }
  // }
  // function toggle_keys_pad() {
  //   var dialPad = document.getElementById('dial-pad')
  //   var auxPad = document.getElementById('aux-pad')
  //   toggle_visible(dialPad);
  //   toggle_visible(auxPad);
  // }
  // function on_load() {
  //   var elem = document.getElementById('shift-key');
  //   elem.onclick = toggle_keys_pad
  //   setTimeout(function() {
  //     UccChat.utils.remove_page_loading();
  //   },1000);
  // }
  // window.onload = on_load;
  // window.isVisible = isVisible
})();
require('./mscs_watchdog')
require('./mscs_date_time')
require('./mscs_alerting')
