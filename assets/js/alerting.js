// assets/js/alerting.js

(function() {
  // helper functions
  console.log('loading alerting.js');

  function safe_call(alerting, name, function_name, args) {
    var plugin = alerting.get_plugin(name);
    var fun = null;
    if (fun = plugin[function_name]) {
      fun(args);
    }
  }

  let Alerting = {
    // not sure we need this, but it will allow us to query the Alerting
    // module to ensure that all the plugins have been initialized
    ready: false,
    // An object containing all the plug-ins
    plugins: {},
    // Keep the default plug-in as its own field. It is not in the list.
    // note that we can't set his here since its defined below. It will be
    // set when init is called
    default_plugin: undefined,
    // called after the page is loaded.
    init: function() {
      console.log('Init alerting.js');
      this.default_plugin = AlertingDefaultPlugin;
      // call the init function on each plugin if it defines one
      Object.keys(this.plugins).forEach(function (key) {
        var init = null;
        if (init = this.plugins[key].init) {
          init(this);
        }
      });
      this.ready = true;
    },
    add_plugin: function(name, plugin) {
      this.plugins[name] = plugin;
    },
    // encapsulate the plugin getter so it will return the named pluging
    // if installed, or the default plugin otherwise
    get_plugin: function(name) {
      var plugin = this.plugins[name];
      if (plugin) {
        return plugin;
      } else {
        return this.default_plugin;
      }
    },
    // ***************
    // The mandatory operational API for all plugins (an interface)
    // ***************

    // Start alerting. This can take 1 or more arguments and passes
    // the arguments to the plugins start method
    start: function(name, ...args) {
      safe_call(this, name, 'start', args)
    },
    stop: function(name, ...args) {
      safe_call(this, name, 'stop', args)
    },
    volume_up: function(name, ...args) {
      safe_call(this, name, 'volume_up', args);
    },
    volume_down: function(name, ...args) {
      safe_call(this, name, 'volume_down', args);
    },
    volume_set: function(name, ...args) {
      safe_call(this, name, 'volume_set', args);
    },
    // We can use this interface to run custom functions on the plugin.
    // This is really an approach of polymorphism. I wound if we should
    // be using OO here?
    //
    // Another approach could be that the application runs custom APIs
    // by getting its plugin first. Like:
    //     UccChat.Alerting.get_plugin('mscs').some_custome_api()
    //
    // This would mean we don't need this extend helper.
    extend: function(name, extension, ...args) {
      var extension = null;
      if (extension = this.get_plugin(name)[extension]) {
        extension(args);
      }
    }
  };

  var AlertingDefaultPlugin = {
    is_alerting: false,
    init: function(alerting) {
      console.log('The optional init callback', alerting);
      // do so setup after the page has been loaded
    },
    start: function(args) {
      this.is_alerting = true;
      console.log('starting alerting with args', args)
    },
    stop: function(args) {
      this.is_alerting = false;
      console.log('stopping alerting with args', args)
    },
    volume_up: function() {},
    volume_set: function(args) {
      // note that calls with splat arguments (...args) come in as an array
      var value = args[0];
      $('#audio-control')[0].volume = value;
    }
  };

  Alerting.default_plugin = AlertingDefaultPlugin;
  window.UccChat.Alerting = Alerting;

  // Just in case we are loaded after the plugins
  document.dispatchEvent(new Event('AlertingLoaded'));

  $(document).ready(function() {
    UccChat.Alerting.init();
  })
})();

