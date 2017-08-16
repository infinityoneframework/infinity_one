//
// Copyright @E-MetroTel 2015
//
(function() {
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

  const transducer_handset = 0;
  const transducer_headset = 1;
  const transducer_handsfree = 2;
  const transducer_all_pairs = 0x3f;

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
    transducer_tx: 0,
    transducer_rx: 0,
    installed_devices: {},
    init: function() {
      if (this.debug) console.log('device_manager init')
      this.enumerateDevices();
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
    },
    set_devices_id: function(devs, installed, type, the_default) {
      if (this.debug) console.log("det_devices_id", devs, installed, type, the_default)
      if (installed[devs[type]])
        this.devices[type] = devs[type]
      else
        this.devices[type] = the_default
    },
    has_headset_device: function() {
      var status = false;
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
        if (mscs.debug) console.log("disconnect tx streams")
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
            DeviceManager.current_device = DeviceManager.devices.headset_input_id
            DeviceManager.webrtc.set_transducer(pair_id)
            break;
          case transducer_handsfree:
            DeviceManager.current_device = DeviceManager.devices.handsfree_input_id
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
      return 0.7;
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
  };

  UccChat.on_connect(function(ucc_chat, socket) {
    console.log('device_manager on_connect');
    window.UcxUcc.DeviceManager = DeviceManager;
    window.UcxUcc.DeviceManager.init();
  });

})();
