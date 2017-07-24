//
// Copyright @E-MetroTel 2015
//

let devices = {
  handsfree_input_id: "",
  handsfree_output_id: "",
  headset_input_id: "",
  headset_output_id: ""
}
let current_device = ""
let installed_devices = []

let transducer_tx = 0;
let transducer_rx = 0;

const mscs = {debug: true}
const transducer_handset = 0
const transducer_headset = 1
const transducer_handsfree = 2
const transducer_all_pairs = 0x3f

// var   apb_volume
// const apb_handset = 1
// const apb_headset = 2
// const apb_handsfree = 3
// const num_vol_steps = 10

// import * as tone_gen from './tone_generator'
// import * as alerting from './alerting'
// import * as sptone from './specialtone'
// import * as paging from './paging'
// import * as feedback from './key_feedback'

let vol_chg = 1
var active_audio_ctrl
var webrtc = null
// var apb_active

$(document).ready(function() {
  active_audio_ctrl = "";
  window.mscs.get_devices = get_devices
  window.mscs.get_installed_devices = get_installed_devices
  window.mscs.has_headset_device = has_headset_device
  // apb_active = apb_handsfree
  // apb_volume = [0, apb_handset, apb_headset, apb_handsfree]
})


//////////
// Public functions

export function set_webrtc(web_rtc) {
  webrtc = web_rtc
}

export function update_transducer() {
  let tx = transducer_tx
  let rx = transducer_rx
  if (tx) connect_transducer_tx(tx.stream_id, tx.pair_id, tx.apb)
  if (rx) connect_transducer_rx(rx.stream_id, rx.pair_id, rx.apb)
}

function get_installed_devices() { return installed_devices }

export function get_device(dev) {
  return devices[dev]
}
export function get_devices() {
  return { devices: devices, current_device: current_device }
}
export function set_devices(devs) {
  if (mscs.debug) console.log("set_devices", devs)

  set_devices_id(devs, installed_devices, "handsfree_input_id", "default")
  set_devices_id(devs, installed_devices, "handsfree_output_id", "default")
  set_devices_id(devs, installed_devices, "headset_input_id", "")
  set_devices_id(devs, installed_devices, "headset_output_id", "")
}

function set_devices_id(devs, installed, type, the_default) {
  if (installed[devs[type]])
    devices[type] = devs[type]
  else
    devices[type] = the_default
}

export function has_headset_device() {
  var status = false;
  if(devices.headset_input_id && devices.headset_output_id)
    status = true;
  return status;
}

export function enumerateDevices() {
  navigator.mediaDevices.enumerateDevices()
  .then(saveDevices)
  .catch(errorCallback)
}

function saveDevices(deviceInfos) {
  if (mscs.debug) console.log('deviceInfos', deviceInfos)
  installed_devices = []
  for (var i = 0; i !== deviceInfos.length; ++i) {
    let device = deviceInfos[i]
    if (device.kind === 'audioinput' || device.kind === "audiooutput") {
      installed_devices[device.deviceId] = device
    }
  }
  if (mscs.debug) console.log('installed_devices', installed_devices)
}

export function load_devices() {
  if (mscs.debug) console.log("load_devices()")
  navigator.mediaDevices.enumerateDevices()
  .then(gotDevices)
  .catch(errorCallback)
}

// export for console access
window.device_manager = {
  get_devices: get_devices,
  current_device: current_device
}
export function get_current_device() {
  return current_device;
}

export function connect_transducer(msg) {
  var audio_ctrl = $('#audio')
  set_active_apb(msg.apb_number)
  if (msg.tx_enable)
    connect_transducer_tx(msg.key, msg.pair_id, msg.apb_number)
  if (msg.rx_enable)
    connect_transducer_rx(msg.key, msg.pair_id, msg.apb_number)
  handle_call_on_hold(msg, audio_ctrl)
}

export function alerting_tone_configuration(msg) {
  switch(msg.transducer_routing) {
    case transducer_headset:
    case transducer_handset:
      // alerting.set_headset_output()
      setSinkId($('#audio-alerting'), devices.headset_output_id)
      break;
    case transducer_handsfree:
      setSinkId($('#audio-alerting'), devices.handsfree_output_id)
      break;
    case transducer_all_pairs:
      break;
    default:
      console.error('Invalid alerting_tone_configuration transducer_routing', msg)
      break;
  }
}

// export function paging_tone_volume_configuration() {
//   // no tone volume is sent for paging
//   // set_tone_volume(2, "paging");
// }

export function transducer_tone_volume(msg) {
  switch(msg.key) {
    case "alerting":
    case "special":
      set_tone_volume(msg.tone_level, msg.key);
      break;
    default:
      console.error('Unknown transducer tone', msg.key)
      break;
  }
}

export function set_tone_volume(level, key) {
  active_audio_ctrl = $('#audio-alerting')[0];
  var tone_volume = 0;
  switch(key) {
    case "alerting":
      tone_volume = alerting.get_vol_step_factor();
      break;
    case "special":
      tone_volume = sptone.get_vol_step_factor();
      break;
    case "paging":
      tone_volume = paging.get_vol_step_factor();
      break;
    default:
      console.error('Unknown transducer tone', key)
      break;
  }
  if (level > 8) level = 8
  if (level < 1) level = 1
  let new_volume = tone_volume;
  if (level > 0)
    new_volume = level * tone_volume;
  if (mscs.debug)
    console.log('set_tone_volume', key, level, new_volume)
  active_audio_ctrl.volume = new_volume
}

export function get_audio_ctrl_volume() {
  return active_audio_ctrl.volume;
}

export function play(audio_control, tone_file) {
  if (mscs.debug)
    console.log("Media player playing tone:", tone_file)
  audio_control.attr('src', tone_file)
  if (mscs.debug)
    console.log("Media player playing tone with audio control:", audio_control)
  audio_control[0].play()
}

export function setSinkId(audio_control, sinkId) {
  let element = audio_control[0]
  if (sinkId) {
    if (typeof element.sinkId != 'undefined') {
      element.setSinkId(sinkId)
      .then(function() {
        if (mscs.debug)
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
    if (mscs.debug)
      console.log('Ignoring setSinkId for no sinkId', sinkId)
  }
}

export function stop(audio_control) {
  audio_control[0].pause()
  audio_control.attr('src','')
}

export function volume_up(active_audio_ctrl) {
  // if (active_audio_ctrl != "") {
  //   switch (active_audio_ctrl.id) {
  //     case "audio":
  //     case "audio-stream":
  //       var apb = get_active_apb()
  //       if (apb_volume[apb] + vol_chg <= num_vol_steps) {
  //          apb_volume[apb] = apb_volume[apb] + vol_chg
  //       } else {
  //          apb_volume[apb] = num_vol_steps
  //       }
  //       active_audio_ctrl.volume = apb_volume[apb]/num_vol_steps
  //       feedback.set_volume(active_audio_ctrl.volume)
  //       break;
  //     case "audio-alerting":
  //       alerting.volume_up()
  //       feedback.set_volume(active_audio_ctrl.volume)
  //       break;
  //     default:
  //       console.error('Unsupported audio control: ', active_audio_ctrl.id);
  //       break;
  //   }
  // }
}

export function volume_down(active_audio_ctrl) {
  // if (active_audio_ctrl != "") {
  //   switch (active_audio_ctrl.id) {
  //     case "audio":
  //     case "audio-stream":
  //       var apb = get_active_apb()
  //       if (apb_volume[apb] - vol_chg >= vol_chg) {
  //          apb_volume[apb] = apb_volume[apb] - vol_chg
  //       } else {
  //          apb_volume[apb] = vol_chg
  //       }
  //       active_audio_ctrl.volume = apb_volume[apb]/num_vol_steps
  //       feedback.set_volume(active_audio_ctrl.volume)
  //       break;
  //     case "audio-alerting":
  //       alerting.volume_down()
  //       feedback.set_volume(active_audio_ctrl.volume)
  //       break;
  //     default:
  //       console.error('Unsupported audio control: ', active_audio_ctrl.id);
  //       break;
  //   }
  // }
}

export function get_rx_volume_parms(msg) {
  // if (msg.default_rx_vol_id == 0x10) {
  //   return(alerting.get_alerting_rx_volume_parms());
  // }
}

export function set_volume_level(active_audio_ctrl, apb, level) {
  // if (active_audio_ctrl.id == "audio-stream" || active_audio_ctrl.id == "audio") {
  //   if (apb == apb_headset || apb == apb_handsfree) {
  //     apb_volume[apb] = level
  //     active_audio_ctrl.volume = level/num_vol_steps
  //   }
  // }
}

// export function get_active_apb() {
//   return(apb_active)
// }

// export function set_active_apb(apb) {
//   apb_active = apb
// }

// export function get_apb_parms() {
//   var apb = get_active_apb()
//   return {apb: apb, current_vol: apb_volume[apb]};
// }

export function set_mute_state(msg) {
  switch (msg.key) {
    case 0:
      if(msg.mute) {
        webrtc.stop_transducer(transducer_tx.pair_id)
      }
      else {
        webrtc.set_transducer(transducer_tx.pair_id)
      }
      break;
    default:
      console.error("Unsupported stream_id:", msg.key)
  }
}

//////////
// Private functions

function gotDevices(deviceInfos) {
  if (mscs.debug) console.log("got_devices")

  $('#devices_handsfree_input_id').html('')
  $('#devices_handsfree_output_id').html('')
  $('#devices_headset_input_id').html('')
  $('#devices_headset_output_id').html('')

  add_devices_message("headset_input_id", "Select an input device")
  add_devices_message("headset_output_id", "Select an output device")

  for (var i = 0; i !== deviceInfos.length; ++i) {
    let device = deviceInfos[i]
    if (device.kind === 'audioinput') {
      add_devices_option("handsfree_input_id", device)
      add_devices_option("headset_input_id", device)
    } else if (device.kind == "audiooutput") {
      add_devices_option("handsfree_output_id", device)
      add_devices_option("headset_output_id", device)
    }
  }
}

function errorCallback(error) {
  console.error('Device Manager Error: ', error)
}

function connect_transducer_tx(stream_id, pair_id, apb) {
  if (stream_id == 0) {
    transducer_tx = {stream_id: stream_id, pair_id: pair_id, apb: apb}
    switch(pair_id) {
      case transducer_headset:
        if (devices.headset_output_id) {
          setSinkId($('#audio'), devices.headset_output_id)
          setSinkId($('#audio-stream'), devices.headset_output_id)
          setSinkId($('#audio-keypad'), devices.headset_output_id)
        }
        break;
      case transducer_handsfree:
        if (devices.handsfree_output_id) {
          setSinkId($('#audio'), devices.handsfree_output_id)
          setSinkId($('#audio-stream'), devices.handsfree_output_id)
          setSinkId($('#audio-keypad'), devices.handsfree_output_id)
        }
        break;
      default:
        console.error("Invalid tx pair_id", pair_id)
    }
  } else if (stream_id == 255) {
    if (mscs.debug) console.log("disconnect tx streams")
    webrtc.stop_transducer(pair_id)
  } else {
    console.warn("connect_transducer tx - unknown stream ID", stream_id)
  }
}
function connect_transducer_rx(stream_id, pair_id, apb) {
  if (stream_id == 0) {
    transducer_rx = {stream_id: stream_id, pair_id: pair_id, apb: apb}
    switch(pair_id) {
      case transducer_headset:
        current_device = devices.headset_input_id
        webrtc.set_transducer(pair_id)
        break;
      case transducer_handsfree:
        current_device = devices.handsfree_input_id
        webrtc.set_transducer(pair_id)
        break;
      default:
        console.warn("Invalid tx pair_id", pair_id)
    }
  } else if (stream_id == 255) {
    if (mscs.debug) console.log("disconnect rx streams", pair_id)
    webrtc.stop_transducer(pair_id)
  } else {
    console.warn("connect_transducer rx - unknown stream ID", stream_id)
  }
}
function add_devices_message(type, message) {
  $('#devices_'+type).append('<option value>'+message+'</option>')
}
function add_devices_option(type, device) {
  let option = ""
  if (devices[type] == device.deviceId) {
    option = '<option selected="selected" value="'+device.deviceId+'">'+device.label+'</option>'
  } else {
    option = '<option value="'+device.deviceId+'">'+device.label+'</option>'
  }
  $('#devices_'+type).append(option)
}

function handle_call_on_hold(msg, audio_ctrl) {
  if (audio_ctrl.attr('src')) {
    if (msg.key == 0) {
      audio_ctrl[0].play()
    }
    else if (msg.key == 255) {
      audio_ctrl[0].pause()
    }
  }
}
