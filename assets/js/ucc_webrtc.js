
import * as device from './device_manager'

const debug = true
const transducer_headset = 1
const transducer_handsfree = 2
const transducer_all_pairs = 0x3f

let AudioContext = window.AudioContext || window.webkitAudioContext || window.mozAudioContext;
var current

function hasUserMedia() {
  navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;
  return !!navigator.getUserMedia;
}

function hasRTCPeerConnection() {
  window.RTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection || window.mozRTCPeerConnection;
  window.RTCSessionDescription = window.RTCSessionDescription || window.webkitRTCSessionDescription || window.mozRTCSessionDescription;
  window.RTCIceCandidate = window.RTCIceCandidate || window.webkitRTCIceCandidate || window.mozRTCIceCandidate;
  return !!window.RTCPeerConnection;
}

export function create() {
  let webrtc = new Webrtc()
  return(webrtc)
}

UccChat.on_load(function(ucc_chat) {
  ucc_chat.webrtc = new Webrtc(ucc_chat)
})
// function checkForWake() {
//   setInterval(function() {
//     if (mscs.webrtc.connectionClosed()) {
//       if (debug) { console.log('Detected closed connection. Resetting the connection') }
//       mscs.webrtc.resetConnection()
//     }
//   }, 3000)
// }

class Webrtc {
  constructor(stunaddr) {
    this.chan = undefined
    this.context = new AudioContext()
    this.stream_hs = null
    this.gain_hf = null
    this.gain_hs = null
    this.initialized = false
    this.theirAudio = document.querySelector('#audio')
    this.mac = $('#mac-address').attr('data-mac')
    this.yourConnection = null
    this.connectedUser = null
    this.stream = null
    this.has_headset = false
    this.stunaddr = stunaddr
    current = this

    // checkForWake()
  }

  start_channel(socket) {
    if (debug) { console.log('webrtc.start_channel') }

    this.chan = socket.channel("webrtc:" + ucxchat.user_id, {
      user: window.ucxchat.username,
      channel_id: window.ucxchat.channel_id
    })

    this.chan.onError( () => true )
    this.chan.onClose( () => true )

    this.chan.on('room:update:name', resp => {
      if (debug) { console.log('room:update', resp) }
    })
    this.chan.on('room:join', resp => {
      console.log('room:join', resp)
    })

    this.chan.join()
      .receive("ok", resp => {
        console.log('Webrtc Joined system channel successfully', resp)
        // handleOnLine()
      })
      .receive("error", resp => {
        console.error('Webrtc Unable to join system channel', resp)
        // handleOffLine()
      })

    this.chan.on("webrtc:login", data => {
      console.log("Got login", data);
      this.onLogin(data.success);
    })
    this.chan.on("webrtc:offer", data => {
      console.log("Got offer", data);
      this.onOffer(data.offer, data.name);
    })
    this.chan.on("webrtc:answer", data => {
      console.log("Got answer", data);
      this.onAnswer(data.answer);
    })
    this.chan.on("webrtc:candidate", data => {
      console.log("Got candidate", data);
      this.onCandidate(data.candidate);
    })
    this.chan.on("webrtc:leave", data => {
      console.log("Got leave", data);
      // console.log("update:line: ", msg)
      this.onLeave();
    })
  }

  send(message) {
    if (this.connectedUser) {
      message.name = this.connectedUser;
    }
    if (debug)
      console.log('pushing for ' + this.mac, message)
    window.chan.push("webrtc:" + this.mac, message)
  }

  set_transducer(pair_id) {
    switch(pair_id) {
      case transducer_headset:
        this.enable_headset_gain(true)
        this.enable_handsfree_gain(false)
        break
      case transducer_handsfree:
        this.enable_headset_gain(false)
        this.enable_handsfree_gain(true)
        break
      case transducer_all_pairs:
        if (debug) console.log('set_transducer all')
        this.enable_headset_gain(true)
        this.enable_handsfree_gain(true)
        break
    }
  }

  enable_headset_gain(enable) {
    if (this.gain_hs) {
      let enabled = 0
      if (enable) enabled = 1
      this.gain_hs.gain.value = enabled
    }
  }

  enable_handsfree_gain(enable) {
    if (this.gain_hf) {
      let enabled = 0
      if (enable) enabled = 1
      this.gain_hf.gain.value = enabled
    }
  }

  stop_transducer(pair_id) {
    switch(pair_id) {
      case transducer_headset:
        this.enable_headset_gain(false)
        break
      case transducer_handsfree:
        this.enable_handsfree_gain(false)
        break
      case transducer_all_pairs:
        //console.log('stop_transducer all')
        this.enable_headset_gain(false)
        this.enable_handsfree_gain(false)
        break
    }
  }

  onLogin(success) {

  }

  onOffer(offer, name) {
    if (offer.to == "" || offer.from == "") {
      if (debug)
        console.log('onOffer error ', offer, 'with name ', name)
      return
    }
    if (debug) console.log('RTC: onOffer', offer)
    this.connectedUser = name

    this.yourConnection.setRemoteDescription(new RTCSessionDescription(offer), function() {
      if (debug) console.log('trying create answer')
      this.create_answer()
    }, function(error) {
      console.warn('setRemoteDescription error ', error)
    })
  }

  onAnswer(answer) {
    if (debug) console.log("RTC: onAnswer", answer)
    this.yourConnection.setRemoteDescription(new RTCSessionDescription(answer));
  }

  onCandidate(candidate) {
    var ice_candidate = new RTCIceCandidate(candidate)
    if (debug) {
      console.log("RTC: onCandidate", candidate, ice_candidate)
      console.log("RTC: onCandidate yourConnection", this.yourConnection)
    }
    this.yourConnection.addIceCandidate(ice_candidate);
  }

  onLeave() {
    if (debug) console.log('RTC: onLeave')
    if (this.yourConnection) {
      this.yourConnection.close();
      this.yourConnection.onicecandidate = null;
      this.yourConnection.onaddstream = null;
      this.connectedUser = null;
      this.theirAudio.src = "";
      this.setupPeerConnection(this.stream);
    }
  }

  create_answer() {
    if (debug) console.log("RTC: create_answer")
    this.yourConnection.createAnswer(function (answer) {
      this.yourConnection.setLocalDescription(answer);
      if (debug) console.log('sending the answer', answer)
      this.send({
        type: "answer",
        answer: answer
      })
    }, function (error) {
      this.send({
        type: "error",
        message: "onOffer error: " + error
      })
      console.warn("onOffer error", error)
    })
  }

  connectionClosed() {
    return this.yourConnection.signalingState === "closed"
  }

  startConnection() {
    if (this.initialized) return

    this.resetConnection()
  }

  resetConnection() {
    this.has_headset = device.has_headset_device()

    this.initialized = true

    if (hasUserMedia()) {
      let contraints_hs = {
        video: false,
        audio: {
          optional: [{sourceId: device.get_device("headset_input_id")}]
        }
      }
      let contraints_hf = {
        video: false,
        audio: {
          optional: [{sourceId: device.get_device("handsfree_input_id")}]
        }
      }

      if (this.has_headset) {
        if (debug) console.log('getUserMedia for headset')
        navigator.getUserMedia(contraints_hs, function (myStream) {
          current.stream_hs = myStream;
        }, function(error) {
          console.error('hf:', error);
        })
      } else {
        if (debug) console.log('skipping getUserMedia for headset')
      }

      navigator.getUserMedia(contraints_hf, function (myStream) {
        var handsfree = current.context.createMediaStreamSource(myStream)
        var mixedOutput = current.context.createMediaStreamDestination()

        window.gain_hf = current.gain_hf = current.context.createGain()

        current.gain_hf.gain.value = 0
        handsfree.connect(current.gain_hf)
        current.gain_hf.connect(mixedOutput)

        if (current.has_headset) {
          if (debug) console.log('found headset. stream_hs:', current.stream_hs)
          var headset = current.context.createMediaStreamSource(current.stream_hs)
          window.gain_hs = current.gain_hs = current.context.createGain()
          current.gain_hs.gain.value = 1
          headset.connect(current.gain_hs)
          current.gain_hs.connect(mixedOutput)
        }

        current.stream = mixedOutput.stream
        window.stream = current.stream

        if (hasRTCPeerConnection()) {
          current.setupPeerConnection(current.stream);
        } else {
          current.send({
            type: "error",
            message: "Sorry, your browser does not support WebRTC."
          })
          alert("Sorry, your browser does not support WebRTC.");
        }
      }, function (error) {
        current.send({
          type: "error",
          message: "Sorry, your browser does not support WebRTC."
        })
        console.error('hs:', error);
      });

    } else {
      current.send({
        type: "error",
        message: "Sorry, your browser does not support WebRTC."
      })
      alert("Sorry, your browser does not support WebRTC.");
    }
  }

  getpeer() {
    return this.yourConnection;
  }

  getStats(key, fields, callback) {
    this.yourConnection.getStats(function(res) {
      var items = []
      var types = []
      res.result().forEach(function(result) {
        if (key == "all" || result.type == key)
        {
          var item = {}
          result.names().forEach(function(name) {
            if (Array.isArray(fields) && fields.length > 0)
            {
              if (fields.indexOf(name) >= 0)
                item[name] = result.stat(name)
            } else {
              item[name] = result.stat(name)
            }
          })
          item.id = result.id
          item.type = result.type
          item.timestamp = result.timestamp
          items.push(item)
        }
        types.push(result.type)
      })
      if (callback)
      {
        callback(items)
      }
    })
  }
  getStatTypes(callback) {
    this.yourConnection.getStats(function(res) {
      var types = []
      res.result().forEach(function(result) {
        types.push(result.type)
      })
      if (callback)
        callback(types)
    })
  }

  setupPeerConnection(stream) {
    if (debug) console.log("RTC: setupPeerConnection", stream)
    var configuration = {
      // TODO: Need to use the configured stun servers
      "iceServers": [{ "url": "stun:" + this.stunaddr }]
    };
    this.yourConnection = new RTCPeerConnection(configuration);

    // Setup stream listening
    this.yourConnection.addStream(stream);
    this.yourConnection.onaddstream = function (e) {
      if (debug) console.log('onaddstream:', e.stream)
      current.theirAudio.src = window.URL.createObjectURL(e.stream);
      device.update_transducer()
    };

    // Setup ice handling
    this.yourConnection.onicecandidate = function (event) {
      let candidate = event.candidate

      if(event.candidate) {
        if (event.candidate.candidate.search(/ udp /i) == -1)
            candidate = -1
        else
          candidate = event.candidate
      }
      if(candidate != -1) {
        current.send({
          name: name,
          type: "candidate",
          candidate: candidate
        });
      }
    };
  }

  startPeerConnection(user) {
    if (debug) console.log("RTC: startPeerConnection", user)
    this.connectedUser = user

    // Begin the offer
    this.yourConnection.createOffer(function (offer) {
      current.send({
        type: "offer",
        offer: offer
      });
      current.yourConnection.setLocalDescription(offer);
    }, function (error) {
      current.send({
        type: "error",
        message: "startPeerConnection error" + error
      })
      console.error("An error has occurred.", error);
    });
  }
}

$(document).ready(function() {
  console.log('ucc_webrtc startup')
  // window.ucc_webrtc = new Webrtc()
})

export default Webrtc;
