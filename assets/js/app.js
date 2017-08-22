// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

require('./ucx_ucc');
require('./ucc_chat')
require('./typing')
require('./ucc_webrtc')
require('./tone_generator')

// import configured plugin js
var plugins = window.ucx_ucc_plugins;
for(var i = 0; i < plugins.length; ++i) {
  require(plugins[i]);
}
window.moment = require('moment');
