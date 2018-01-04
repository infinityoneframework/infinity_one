require('./device_manager');
(function() {
  console.log('loading webrtc')

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
  UccChat.on_connect(function(ucc_chat, socket) {
    console.log('webrtc on_connect');
    WebRTC.init(ucc_chat.socket, ucc_chat.ucxchat.user_id,
      ucc_chat.ucxchat.username);
  });

  let WebRTC = {
    callbacks: {
      onCall: [],
      onOffer: [],
      onAnswer: [],
      onLeave: [],
      onHangup: [],
    },
    callType: 'video',
    localVideo: null,
    remoteVideo: null,
    // localAudio: undefined,
    remoteAudio: undefined,
    constraints: function() {
      console.log('UcxUcc', UcxUcc);
      console.log('Mscs', UcxUcc.Mscs);
      var dm = false;
      console.log('DeviceManager', UcxUcc.DeviceManager);
      if (UcxUcc.DeviceManager) {
      console.log('dm 1', dm);
        dm = UcxUcc.DeviceManager;
      } else if (UcxUcc.Mscs) {
      console.log('dm 2', dm);
        dm = UcxUcc.Mscs.DeviceManager;
      }
      console.log('dm', dm);
      if (dm) {
        if (this.callType == 'mscs' || this.callType == 'audio') {
          return {
            audio: {deviceid: {exact: dm.get_device("handsfree_input_id")}}
          }
        } else {
          return {
            video: {deviceid: {exact: dm.get_device("video_input_id")}},
            audio: {deviceid: {exact: dm.get_device("handsfree_input_id")}}
          }
        }
      } else {
        console.error('DeviceManager not defined!');
      }
    },
    setVideoElements: function() {
      WebRTC.localVideo =
        $(`.webrtc-video .video-item[data-username="${WebRTC.localUsername}"] video`)[0];
      WebRTC.remoteVideo = $('.webrtc-video .main-video video')[0];
    },
    setAudioElements: function() {
      WebRTC.remoteAudio = $('#audio-stream')[0]
      // WebRTC.remoteAudio = UcxUcc.DeviceManager.get_device('handsfree_output_id')
    },
    init: function(socket, localName, localUsername) {
      console.log('init', localName, localUsername)
      this.socket = socket;
      this.localName = localName;
      this.localUsername = localUsername;
      this.create_channel();
    },
    setRemoteName: function(name) {
      console.log('setRemoteName')
      this.remoteName = name;
    },
    setLocalName: function(name) {
      console.log('setLocalName')
      this.localName = name;
    },
    start: function() {
      console.log('start')
      this.callType = 'video';
      WebRTC.setVideoElements();
      WebRTC.startConnection();
    },
    start_mscs: function() {
      this.callType = 'mscs';
      WebRTC.setAudioElements();
      WebRTC.startConnection();
    },
    call: function(remoteName) {
      trace('Starting call')
      setTimeout(() => {
        WebRTC.remoteName = remoteName
        var callbacks = WebRTC.callbacks.onCall;
        for (var i = 0; i < callbacks.length; ++i) {
          callbacks[i]();
        }
        if (remoteName.length > 0) {
          WebRTC.startPeerConnection(remoteName);
        }
      }, 1000)
    },
    audio_call: function(remoteName) {
      trace('Starting call')
      setTimeout(() => {
        WebRTC.remoteName = remoteName
        var callbacks = WebRTC.callbacks.onCall;
        for (var i = 0; i < callbacks.length; ++i) {
          callbacks[i]();
        }
        if (remoteName.length > 0) {
          WebRTC.startPeerConnection(remoteName);
        }
      }, 1)
    },
    hangup: function() {
      trace('Ending call')
      var callbacks = WebRTC.callbacks.onHangup;
      for (var i = 0; i < callbacks.length; ++i) {
        callbacks[i]();
      }
      WebRTC.send({type: "leave"});
      WebRTC.onLeave();
    },
    create_channel: function() {
      console.log('create_channel')
      var chan = this.socket.channel("webrtc:user-" + this.localName, {});
      WebRTC.chan = chan;

      chan.on("webrtc:login", function(data) {
        trace('Got login');
        WebRTC.onLogin(data.success);
      });
      chan.on("webrtc:offer", function(data) {
        trace('Got Offer');
        WebRTC.onOffer(data.offer, data.name);
      });
      chan.on("webrtc:answer", function(data) {
        trace('Got answer');
        WebRTC.onAnswer(data.answer);
      });
      chan.on("webrtc:candidate", function(data) {
        trace('Got candidate');
        WebRTC.onCandidate(data.candidate);
      });
      chan.on("webrtc:leave", function(data) {
        trace('Got leave');
        WebRTC.onLeave();
      });

      chan.join()
        .receive("ok", resp => { console.log("Joined successfully", resp) })
        .receive("error", resp => { console.log("Unable to join", resp) })
    },
    send: function(message) {
      if (WebRTC.connectedUser) {
        message.name = WebRTC.connectedUser;
      }
      WebRTC.chan.push("webrtc:user-" + WebRTC.localName, message)
    },
    onOffer: function(offer, name) {
      console.log('onOffer', offer)
      WebRTC.connectedUser = name;
      WebRTC.yourConnection.setRemoteDescription(new RTCSessionDescription(offer));

      WebRTC.yourConnection.createAnswer(function(answer) {
        var callbacks = WebRTC.callbacks.onOffer;
        for (var i = 0; i < callbacks.length; ++i) {
          callbacks[i](offer, name);
        }
        WebRTC.yourConnection.setLocalDescription(answer);
        WebRTC.send({
          type: "answer",
          answer: answer
        });
      }, function(error) {
        WebRTC.send({
          type: "error",
          message: "onOffer error: " + error
        });
        console.log('onOffer error', error)
      });
    },
    onAnswer: function(answer) {
      console.log('onAnswer')
      var callbacks = WebRTC.callbacks.onAnswer;
      for (var i = 0; i < callbacks.length; ++i) {
        callbacks[i](answer);
      }
      WebRTC.yourConnection.setRemoteDescription(new RTCSessionDescription(answer));
    },
    onCandidate: function(candidate) {
      console.log('onCandidate')
      WebRTC.yourConnection.addIceCandidate(new RTCIceCandidate(candidate));
    },
    onLeave: function() {
      console.log('onLeave')
      if (WebRTC.yourConnection) {
        var callbacks = WebRTC.callbacks.onLeave;
        for (var i = 0; i < callbacks.length; ++i) {
          callbacks[i]();
        }
        WebRTC.yourConnection.close();
        WebRTC.stream.getTracks().forEach(function (track) {
          track.stop();
        });
        if (WebRTC.callType == 'video') {
          WebRTC.connectedUser = null;
          WebRTC.remoteVideo.src = null;
        } else {
          WebRTC.remoteAudio = null;
        }
        WebRTC.yourConnection.onicecandate = null;
        WebRTC.yourConnection.onaddstream = null;
        WebRTC.setupPeerConnection(WebRTC.stream)
      }
    },
    hasUserMedia: function() {
      navigator.getUserMedia = navigator.getUserMedia ||
        navigator.webkitGetUserMedia || navigator.mozGetUserMedia ||
        navigator.msGetUserMedia;
      return !!navigator.getUserMedia;
    },
    hasRTCPeerConnection: function() {
      window.RTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection || window.mozRTCPeerConnection;
      window.RTCSessionDescription = window.RTCSessionDescription || window.webkitRTCSessionDescription || window.mozRTCSessionDescription;
      window.RTCIceCandidate = window.RTCIceCandidate || window.webkitRTCIceCandidate || window.mozRTCIceCandidate;
      return !!window.RTCPeerConnection;
    },
    startConnection: function() {
      trace('startConnection')
      console.log('startConnection', UcxUcc)
      if (WebRTC.hasUserMedia()) {
        trace('hasUserMedia')
        // var constraints = {
        //   video: {deviceid: {exact: ucxucc.devicemanager.get_device("video_input_id")}},
        //   audio: {deviceid: {exact: ucxucc.devicemanager.get_device("handsfree_input_id")}}
        // }
        navigator.getUserMedia(WebRTC.constraints(), function(myStream) {
          trace('getUserMedia callback')
          WebRTC.stream = myStream;

          if (WebRTC.hasRTCPeerConnection()) {
            trace('hasRTCPeerConnection')
            WebRTC.setupPeerConnection(myStream);
          } else {
            trace('does not hasRTCPeerConnection')
            WebRTC.send({
              type: "error",
              message: "Sorry, your browser does not support WebRTC."
            })
            alert("Sorry, your browser does not support WebRTC.");
          }
        }, function(error) {
            trace('getUserMedia error', error)
            WebRTC.send({
              type: "error",
              message: "Sorry, your browser does not support WebRTC."
            })
          console.log(error);
        });
      } else {
        trace('browser does not support error')
        WebRTC.send({
          type: "error",
          message: "Sorry, your browser does not support WebRTC."
        })
        alert("Sorry, your browser does not support WebRTC.");
      }
    },

    setupPeerConnection: function(stream) {
      trace('setupPeerConnection');
      var configuration = {
        "iceServers": [{ "urls": window.UcxUcc.iceServers }]
      };
      WebRTC.yourConnection = new RTCPeerConnection(configuration);

      console.log('yourConnection', WebRTC.yourConnection)

      // Setup stream listening
      WebRTC.yourConnection.addStream(stream);
      if (WebRTC.callType == 'video') {
        WebRTC.localVideo.srcObject = stream;

        WebRTC.yourConnection.onaddstream = function (e) {
          WebRTC.remoteVideo.srcObject = e.stream;
        };
      } else {
        WebRTC.yourConnection.onaddstream = function (e) {
          WebRTC.remoteAudio.srcObject = e.stream;
        };
      }

      // Setup ice handling
      WebRTC.yourConnection.onicecandidate = function (event) {
        var candidate = event.candidate;

        if (candidate) {
          if (WebRTC.callType == 'mscs') {
            if (candidate.candidate.search(/ udp /i) == -1) {
              return;
            }
          }

          WebRTC.send({
            name: name,
            type: "candidate",
            candidate: candidate
          });
        }
      };
    },
    startPeerConnection: function(user) {
      trace('startPeerConnection')
      WebRTC.connectedUser = user;

      // Begin the offer
      WebRTC.yourConnection.createOffer(function(offer) {
        WebRTC.send({
          type: "offer",
          offer: offer
        });
        WebRTC.yourConnection.setLocalDescription(offer);
      }, function (error) {
        WebRTC.send({
          type: "error",
          message: "startPeerConnection error" + error
        })
        console.log("An error has occurred.");
      });
    }
  };

  window.WebRTC = WebRTC
  // WebRTC.init()
})();
