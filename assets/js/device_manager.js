//
// Copyright @E-MetroTel 2015-2018
//
// assets/js/device_manager.js

(function() {
  if (UcxUcc.trace_startup) console.log('loading device_manager.js');

  const disconnect_stream = 255;

  function safe_call(device_manager, name, function_name, args) {
    var plugin = device_manager.get_plugin(name);
    var fun = null;
    if (fun = plugin[function_name]) {
      fun(args);
    }
  }

  function trace(text) {
    if (text[text.length - 1] === '\n') {
      text = text.substring(0, text.length - 1);
    }
    if (window.performance) {
      var now = (window.performance.now() / 1000).toFixed(3);
      console.log(now + ': ' + text);
    } else {
      console.log(text);
    }
  }

  var DeviceManager = {
    // query module to ensure that all the plugins have been initialized
    ready: false,
    // An object containing all the plug-ins
    plugins: {},
    // Keep the default plug-in as its own field. It is not in the list.
    // note that we can't set his here since its defined below. It will be
    // set when init is called
    default_plugin: undefined,
    // called after the page is loaded.
    debug: true,
    devices: {
      handsfree_input_id: "",
      handsfree_output_id: "",
      headset_input_id: "",
      headset_output_id: "",
      video_input_id: "",
      current_device: ""
    },
    installed_devices: {},

    init: function() {
      console.log('init device_manager.js');
      this.default_plugin = DeviceManagerDefaultPlugin;
      // call the init function on each plugin if it defines one
      Object.keys(this.plugins).forEach(function (key) {
        var init = null;
        console.log('init plugins, key', key);
        if (init = UccChat.DeviceManager.plugins[key].init) {
          init(UccChat.DeviceManager);
        }
      });
      this.ready = true;

      this.enumerateDevices();
    },
    add_plugin: function(name, plugin) {
      this.plugins[name] = plugin;
    },
    get_plugin: function(name) {
      var plugin = this.plugins[name];
      if (plugin) {
        return plugin;
      } else {
        return this.default_plugin;
      }
    },
    get_device: function(dev) {
      if (this.debug) console.log("get_device", dev)
      return this.devices[dev]
    },
    get_devices: function() {
      if (this.debug) console.log("get_devices")
      return { devices: this.devices, current_device: this.devices.current_device }
    },
    set_devices: function(devs) {
      if (this.debug) console.log("set_devices", devs)
      var installed_devices = this.installed_devices;

      this.set_devices_id(devs, installed_devices, "handsfree_input_id", "default")
      this.set_devices_id(devs, installed_devices, "handsfree_output_id", "default")
      this.set_devices_id(devs, installed_devices, "headset_input_id", "")
      this.set_devices_id(devs, installed_devices, "headset_output_id", "")
      this.set_devices_id(devs, installed_devices, "video_input_id", "")
    },
    set_devices_id: function(devs, installed, type, the_default) {
      if (this.debug) console.log("set_devices_id", devs, installed, type, the_default)
      if (installed[devs[type]])
        this.devices[type] = devs[type]
      else
        this.devices[type] = the_default
    },
    has_headset_device: function() {
      var status = false;
      if (this.debug) {
        console.log('has_headset_device devices', this.devices);
        console.log('has_headset_device installed devices', this.installed_devices);
      }
      if(this.devices.headset_input_id && this.devices.headset_output_id)
        status = true;
      if (this.debug) console.log("has_headset_device", status)
      return status;
    },
    enumerateDevices: function() {
      if (DeviceManager.debug) console.log('device manager enumerateDevices')
      navigator.mediaDevices.enumerateDevices()
      .then(DeviceManager.saveDevices)
      .catch(DeviceManager.errorCallback)
    },
    saveDevices: function(deviceInfos) {
      if (DeviceManager.debug) console.log('saveDevices deviceInfos', deviceInfos)
      DeviceManager.installed_devices = {}
      let devices = []
      for (var i = 0; i !== deviceInfos.length; ++i) {
        let device = deviceInfos[i]
        if (device.kind === 'audioinput' || device.kind === "audiooutput" || device.kind === "videoinput") {
          DeviceManager.installed_devices[device.deviceId] = device
          devices.push({kind: device.kind, label: device.label, id: device.deviceId})
        } else {
          if (this.debug) { console.log('---------- other device', device); }
        }
      }
      UcxUcc.installed_devices = devices
      if (DeviceManager.debug) console.log('installed_devices', devices)

      setTimeout(() => {
        var event = new Event('device_manager_init');
        document.dispatchEvent(event);
      }, 100);
    },
    load_devices: function() {
      if (DeviceManager.debug) console.log("load_devices()")
      navigator.mediaDevices.enumerateDevices()
      .then(DeviceManager.gotDevices)
      .catch(DeviceManager.errorCallback)
    },
    get_current_device: function() {
      if (this.debug) console.log("get_current_device")
      return this.devices.current_device;
    },
    setSinkId: function(audio_control, sinkId) {
      if (DeviceManager.debug) console.log("setSinkId", audio_control, sinkId)
      let element = audio_control[0]
      if (sinkId) {
        if (typeof element.sinkId != 'undefined') {
          element.setSinkId(sinkId)
          .then(function() {
            if (DeviceManager.debug)
              console.log('Success, audio output device attached', sinkId)
          })
          .catch(function(error) {
            var errorMessage = error;
            if (error.name === 'SecurityError') {
              errorMessage = 'You need to use HTTPS for selecting audio output ' +
                'device: ' + error
            }
          });
        } else {
          console.error("Browser does not support output device selection.")
        }
      } else {
        if (DeviceManager.debug)
          console.log('Ignoring setSinkId for no sinkId', sinkId)
      }
    },
    set_sink_id_headset_output_id_audio: function() {
      this.setSinkId($('#audio'), this.devices.headset_output_id);
    },
    set_sink_id_headset_output_id_audio_stream: function() {
      this.setSinkId($('#audio-stream'), this.devices.headset_output_id);
    },
    set_sink_id_handsfree_output_id_audio: function() {
      this.setSinkId($('#audio'), this.devices.handsfree_output_id);
    },
    set_sink_id_handsfree_output_id_audio_stream: function() {
      this.setSinkId($('#audio-stream'), this.devices.handsfree_output_id);
    },
    set_headset_input_id_active: function() {
      this.devices.current_device = this.devices.headset_input_id;
    },
    set_handsfree_input_id_active: function() {
      this.devices.current_device = this.devices.handsfree_input_id;
    },
    stop: function(audio_control) {
      if (DeviceManager.debug) console.log("device manager stop")
      audio_control[0].pause()
      audio_control.attr('src','')
    },
    get_audio_control: function() {
      return $('#audio');
    },
    get_audio_alerting_control: function() {
      return $('#audio-alerting');
    },
    get_audio_ctrl_audio: function() {
      return document.getElementById('audio');
    },
    get_audio_ctrl_audio_stream: function() {
      return document.getElementById('audio-stream');
    },
    get_audio_ctrl_alerting: function() {
      return document.getElementById('audio-alerting');
    },
    get_audio_ctrl: function(audio_control) {
      return document.getElementById(audio_control);
    },
    gotDevices: function(deviceInfos) {
      if (DeviceManager.debug) console.log("gotDevices", deviceInfos)
    },
    errorCallback: function(error) {
      console.error('Device Manager Error: ', error)
    },
    set_mute_status: function(state) {
      if (this.debug) console.log("set_mute_status", state)
    },
    volume_increment: function(device, increment) {
      if (this.debug) console.log("volume_increment")
    },
    volume_decrement: function(device, decrement) {
      if (this.debug) console.log("volume_decrement")
    },
    call_on_hold: function(key, audio_ctrl) {
      if (this.debug) { console.log('call_on_hold, key', key, 'audio_ctrl', audio_ctrl) }
      if (audio_ctrl.attr('src')) {
        if (key == 0) {
          audio_ctrl[0].play()
        }
        else if (key == disconnect_stream) {
          audio_ctrl[0].pause()
        }
      }
    },

    // ***************
    // The mandatory operational API for all plugins (an interface)
    // ***************

    extend: function(name, extension, ...args) {
      var extension = null;
      if (extension = this.get_plugin(name)[extension]) {
        extension(args);
      }
    },
  };

  var DeviceManagerDefaultPlugin = {
    is_device_manager: false,
    init: function() {
      console.log('The optional init callback');
      // do so setup after the page has been loaded
    },
    start: function(args) {
      this.is_device_manager = true;
      console.log('starting device_manager with args', args)
    },
    stop: function(args) {
      this.is_device_manager = false;
      console.log('stopping device_manager with args', args)
    },
    volume_up: function() {},
    volume_set: function(args) {
      // note that calls with splat arguments (...args) come in as an array
      var value = args[0];
      $('#audio-control')[0].volume = value;
    },
    get_device: function(args) {},
    get_devices: function(args) {},
    set_devices: function(args) {},
    set_devices_id: function(args) {}
  };

  DeviceManager.default_plugin = DeviceManagerDefaultPlugin;
  window.UccChat.DeviceManager = DeviceManager;

  // Just in case we are loaded after the plugins
  document.dispatchEvent(new Event('DeviceManagerLoaded'));

  UccChat.on_connect(function(ucc_chat, socket) {
    console.log('device_manager on_connect');
    window.UccChat.DeviceManager = DeviceManager;
    setTimeout(function() {
      window.UccChat.DeviceManager.init();
    }, 1500);
  });

})();
