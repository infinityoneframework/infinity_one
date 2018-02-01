//
// Copyright @E-MetroTel 2015-2018
//
// assets/js/device_manager.js

(function() {
  // helper functions
  console.log('loading device_manager.js');

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
/*
  const transducer_handset = 0;
  const transducer_headset = 1;
  const transducer_handsfree = 2;
  const transducer_all_pairs = 0x3f;
*/

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
/*
    devices: {
      handsfree_input_id: "",
      handsfree_output_id: "",
      headset_input_id: "",
      headset_output_id: "",
      video_input_id: "",
      current_device: ""
    },
    active_audio_ctrl: undefined,
    transducer_tone_level: 0,
    transducer_tx: 0,
    transducer_rx: 0,
    installed_devices: {},
*/
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
    // ***************
    // The mandatory operational API for all plugins (an interface)
    // ***************

    get_device: function(name, ...args) {
      safe_call(this, name, 'get_device', args)
    },
    get_devices: function(name, ...args) {
      safe_call(this, name, 'get_devices', args)
    },
    set_devices: function(name, ...args) {
      safe_call(this, name, 'set_devices', args)
    },
    set_devices_id: function(name, ...args) {
      safe_call(this, name, 'set_devices_id', args)
    },
    has_headset_device: function(name, ...args) {
      safe_call(this, name, 'has_headset_device', args)
    },
    set_webrtc: function(name, ...args) {
      safe_call(this, name, 'set_webrtc', args)
    },
    enumerateDevices: function(name, ...args) {
      safe_call(this, name, 'enumerateDevices', args)
    },
    save_devices: function(name, ...args) {
      safe_call(this, name, 'save_devices', args)
    },
    load_devices: function(name, ...args) {
      safe_call(this, name, 'load_devices', args)
    },
    get_current_device: function(name, ...args) {
      safe_call(this, name, 'get_current_device', args)
    },
    volume_up: function(name, ...args) {
      safe_call(this, name, 'volume_up', args);
    },
    volume_down: function(name, ...args) {
      safe_call(this, name, 'volume_down', args);
    },
    set_volume_level: function(name, ...args) {
      safe_call(this, name, 'set_volume_level', args);
    },
    get_volume: function(name, ...args) {
      safe_call(this, name, 'get_volume', args);
    },
    set_tone_volume: function(name, ...args) {
      safe_call(this, name, 'set_tone_volume', args);
    },
    transducer_tone_volume: function(name, ...args) {
      safe_call(this, name, 'transducer_tone_volume', args);
    },
    extend: function(name, extension, ...args) {
      var extension = null;
      if (extension = this.get_plugin(name)[extension]) {
        extension(args);
      }
    },
  };

/*
  UccChat.on_connect(function(ucc_chat, socket) {
    console.log('device_manager on_connect');
    window.UccChat.DeviceManager = DeviceManager;
    setTimeout(function() {
      window.UccChat.DeviceManager.init();
    }, 1500);
  });
*/

  $(document).ready(function() {
  });

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
    }
  };

  DeviceManager.default_plugin = DeviceManagerDefaultPlugin;
  window.UccChat.DeviceManager = DeviceManager;

  // Just in case we are loaded after the plugins
  document.dispatchEvent(new Event('DeviceManagerLoaded'));

  $(document).ready(function() {
    UccChat.DeviceManager.init();
  })
})();

/*
(function() {
  if (UcxUcc.trace_startup) { console.log('loading device_manager'); }
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

  const apb_handset = 1;
  const apb_headset = 2;
  const apb_handsfree = 3;
  const num_vol_steps = 10;

  const vol_chg = 1;

  let DeviceManager = {
    debug: true,
    devices: {
      handsfree_input_id: "",
      handsfree_output_id: "",
      headset_input_id: "",
      headset_output_id: "",
      video_input_id: "",
      current_device: ""
    },
    active_audio_ctrl: undefined,
    transducer_tone_level: 0,
    transducer_tx: 0,
    transducer_rx: 0,
    installed_devices: {},
    apb_volume: [0, apb_handset, apb_headset, apb_handsfree],
    apb_active: apb_handsfree,
    init: function() {
      if (this.debug) console.log('device_manager init')
      this.enumerateDevices();
      let apb = this.get_active_apb()
      let volume = this.apb_volume[apb] / num_vol_steps;

      let audio = document.getElementById('audio')
      let stream = document.getElementById('audio-stream')
      let keypad = document.getElementById('audio-keypad')

      console.log('apb_volumes', this.apb_volume[2],this.apb_volume[3])
      console.log('control volumes', audio.volume, stream.volume)

      audio.volume = stream.volume = keypad.volume = volume;

      var event = new Event('alerting_ctrl');
      event.topic = 'device_manager:init';
      event.value = this;
      document.querySelector('body').dispatchEvent(event);

    },
    set_webrtc: function(web_rtc) {
      this.webrtc = web_rtc
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
      console.log('has_headset_device devices', this.devices);
      console.log('has_headset_device installed devices', this.installed_devices);
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
          console.log('---------- other device', device)
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
    stop: function(audio_control) {
      if (DeviceManager.debug) console.log("device manager stop")
      audio_control[0].pause()
      audio_control.attr('src','')
    },
    gotDevices: function(deviceInfos) {
      if (DeviceManager.debug) console.log("gotDevices", deviceInfos)
    },
    errorCallback: function(error) {
      console.error('Device Manager Error: ', error)
    },
    update_transducer: function() {
      let tx = this.transducer_tx
      let rx = this.transducer_rx
      if (tx) this.connect_transducer_tx(tx.stream_id, tx.pair_id, tx.apb)
      if (rx) this.connect_transducer_rx(rx.stream_id, rx.pair_id, rx.apb)
    },
    connect_transducer: function(msg) {
      if (this.debug) console.log("connect_transducer", msg)

      var audio_ctrl = $('#audio');

      this.set_active_abp(msg.apb_number);
      if (msg.tx_enable) {
        this.connect_transducer_tx(msg.key, msg.pair_id, msg.apb_number)
      }
      if (msg.rx_enable) {
        this.connect_transducer_rx(msg.key, msg.pair_id, msg.apb_number)
      }
      this.handle_call_on_hold(msg, audio_ctrl)
    },
    connect_transducer_tx: function(stream_id, pair_id, apb) {
      if (stream_id == 0) {
        this.transducer_tx = {stream_id: stream_id, pair_id: pair_id, apb: apb}

        switch(pair_id) {
          case transducer_headset:
            if (DeviceManager.devices.headset_output_id) {
              DeviceManager.setSinkId($('#audio'), DeviceManager.devices.headset_output_id)
              DeviceManager.setSinkId($('#audio-stream'), DeviceManager.devices.headset_output_id)
              DeviceManager.setSinkId($('#audio-keypad'), DeviceManager.devices.headset_output_id)
            }
            break;
          case transducer_handsfree:
            if (DeviceManager.devices.handsfree_output_id) {
              DeviceManager.setSinkId($('#audio'), DeviceManager.devices.handsfree_output_id)
              DeviceManager.setSinkId($('#audio-stream'), DeviceManager.devices.handsfree_output_id)
              DeviceManager.setSinkId($('#audio-keypad'), DeviceManager.devices.handsfree_output_id)
            }
            break;
          default:
            console.error("Invalid tx pair_id", pair_id)
        }
      } else if (stream_id == 255) {
        if (UcxUcc.debug) console.log("disconnect tx streams")
        DeviceManager.webrtc.stop_transducer(pair_id)
      } else {
        console.warn("connect_transducer tx - unknown stream ID", stream_id)
      }
    },
    connect_transducer_rx: function(stream_id, pair_id, apb) {
      if (stream_id == 0) {
        this.transducer_rx = {stream_id: stream_id, pair_id: pair_id, apb: apb}
        switch(pair_id) {
          case transducer_headset:
            DeviceManager.devices.current_device = DeviceManager.devices.headset_input_id
            DeviceManager.webrtc.set_transducer(pair_id)
            break;
          case transducer_handsfree:
            DeviceManager.devices.current_device = DeviceManager.devices.handsfree_input_id
            DeviceManager.webrtc.set_transducer(pair_id)
            break;
          default:
            console.warn("Invalid tx pair_id", pair_id)
        }
      } else if (stream_id == 255) {
        if (DeviceManager.debug) console.log("disconnect rx streams", pair_id)
        DeviceManager.webrtc.stop_transducer(pair_id)
      } else {
        console.warn("connect_transducer rx - unknown stream ID", stream_id)
      }
    },
    handle_call_on_hold: function(msg, audio_ctrl) {
      if (audio_ctrl.attr('src')) {
        if (msg.key == 0) {
          audio_ctrl[0].play()
        }
        else if (msg.key == 255) {
          audio_ctrl[0].pause()
        }
      }
    },
    get_audio_ctrl_volume: function() {
      if (this.debug) console.log("get_audio_ctrl_volume")
      //return 0.7;
      var active_audio_ctrl = document.getElementById('audio-alerting');
      return active_audio_ctrl.volume;
    },
    get_active_apb: function() {
      if (this.debug) console.log("get_active_apb")
      return this.apb_active;
    },
    set_active_abp: function(apb) {
      if (this.debug) console.log("set_active_apb", apb)
      this.apb_active = apb;
    },
    get_apb_parms: function() {
      if (this.debug) console.log("get_apb_parms")
      var apb = this.get_active_apb();
      return {apb: apb, current_vol: this.apb_volume[apb]};
    },
    set_mute_state: function(msg) {
      if (this.debug) console.log("set_mute_state", msg)
      switch(msg.key) {
        case 0:
          if (msg.mute) {
            this.webrtc.stop_transducer(this.transducer_tx.pair_id);
          } else {
            this.webrtc.set_transducer(this.transducer_tx.pair_id);
          }
          break;
        default:
          console.log('Unsupported stream_id:', msg.key);
      }
    },
    volume_up: function(active_control) {
      if (active_control && active_control != "") {
        let control = document.getElementById(active_control);

        switch (active_control) {
          case "audio":
          case "audio-stream":
            let apb = this.get_active_apb()
            console.log('apb', apb)
            console.log('apb_volume[apb]', this.apb_volume[apb])
            console.log('current volume', control.volume)


            if (this.apb_volume[apb] + vol_chg <= num_vol_steps) {
              this.apb_volume[apb] += vol_chg;
              $('.keys.volume .vol-down').removeClass('disabled')
            } else {
              this.apb_volume[apb] = num_vol_steps;
              $('.keys.volume .vol-up').addClass('disabled')
            }
            let volume = this.apb_volume[apb] / num_vol_steps;
            console.log('new volume', volume)
            control.volume = volume;
            this.feedback.set_volume(volume);
            break;
          case "audio-alerting":
            this.Alerting.volume_up();
            this.feedback.set_volume(control.volume);
            break
          default:
            console.error('Unsupported audio control: ', active_control);
            break;
        }
      }
    },
    volume_down: function(active_control) {
      if (active_control && active_control != "") {
        let control = document.getElementById(active_control);

        switch (active_control) {
          case "audio":
          case "audio-stream":
            let apb = this.get_active_apb()

            if (this.apb_volume[apb] - vol_chg >= vol_chg) {
              this.apb_volume[apb] -= vol_chg;
              $('.keys.volume .vol-up').removeClass('disabled')
            } else {
              this.apb_volume[apb] = vol_chg;
              $('.keys.volume .vol-down').addClass('disabled')
            }
            let volume = this.apb_volume[apb] / num_vol_steps;
            control.volume = volume;
            this.feedback.set_volume(volume);
            break;
          case "audio-alerting":
            this.Alerting.volume_down();
            this.feedback.set_volume(control.volume);
            break
          default:
            console.error('Unsupported audio control: ', active_control);
            break;
        }
      }
    },
    set_volume_level: function(active_audio_control, abp, level) {
      if (active_audio_control == "audio-stream" || active_audio_control == "audio") {
        if (apb == apb_headset || apb == apb_handsfree) {
          let control = document.getElementById(active_audio_control);
          this.apb_volume[apb] = level
          control.volume = level / num_vol_steps;
        }
      }
    },
    get_volume(key) {
      switch(key) {
        case "alerting":
        case "special":
        case "paging":
          var active_audio_ctrl = document.getElementById('audio-alerting');
          return active_audio_ctrl.volume;
          break;
        default:
          console.error("Unknown transducer tone", key);
          break;
      }
    },
    set_tone_volume: function(level, key) {
      this.active_audio_ctrl = document.getElementById('audio-alerting');
      console.log('set_tone_volume active_audio_ctrl.volume', this.active_audio_ctrl.volume);
      var tone_volume = 0;
      var new_volume = 0;

      switch(key) {
        case "alerting":
          tone_volume = this.Alerting.get_vol_step_factor();
          break;
        case "special":
          tone_volume = this.SpecialTone.get_vol_step_factor();
          break;
        case "paging":
          tone_volume = this.Paging.get_vol_step_factor();
          break;
        default:
          console.error("Unknown transducer tone", key);
          break;
      }
      if (level > 8) level = 8;
      if (level < 1) level = 1;

      // let new_volume = tone_volume;
      if (level > 0) {
        new_volume = level / tone_volume;
      }

      if (this.debug)
        console.log('set_tone_volume', key, level, tone_volume, new_volume)

//      this.active_audio_ctrl.volume = new_volume;
    },
    transducer_tone_volume: function(msg) {
      console.log('transducer_tone_volume', msg);
      switch (msg.key) {
        case "alerting":
        case "special":
          this.set_transducer_tone_level(msg.tone_level);
          this.set_tone_volume(msg.tone_level, msg.key);
          break;
        default:
          console.error('Unknown transducer tone', msg.key)
          break;
      }
    },
    set_transducer_tone_level: function(level) {
      this.transducer_tone_level = level;
    },
    get_transducer_tone_level: function() {
      this.transducer_tone_level;
    },
    feedback: {
      set_volume: function(value) {
        console.log('feedback: set_volume', value);
        var event = new Event('alerting_ctrl');
        event.topic = 'set_volume';
        event.value = value;
        document.querySelector('body').dispatchEvent(event);
      }
    },
    Alerting: {
      volume_up: function() {
        console.log('Alerting volume_up');
        var event = new Event('alerting_ctrl');
        event.topic = 'volume_up';
        document.querySelector('body').dispatchEvent(event);
      },
      volume_down: function() {
        console.log('Alerting volume_down');
        var event = new Event('alerting_ctrl');
        event.topic = 'volume_down';
        document.querySelector('body').dispatchEvent(event);
      },
      get_vol_step_factor: function() {
        return 8;
      }
    },
    SpecialTone: {
      get_vol_step_factor: function() {
        return 8;
      }
    },
    Paging: {
      get_vol_step_factor: function() {
        return 8;
      }
    }
  };

  UccChat.on_connect(function(ucc_chat, socket) {
    console.log('device_manager on_connect');
    window.UcxUcc.DeviceManager = DeviceManager;
    setTimeout(function() {
      window.UcxUcc.DeviceManager.init();
    }, 1500);
  });
  $(document).ready(function() {
  });

  if (UcxUcc.trace_startup) { console.log('complete loading device_manager'); }
})();
*/
