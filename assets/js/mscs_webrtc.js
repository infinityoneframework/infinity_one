(function() {
  console.log('loading mscs_webrtc');
  const transducer_headset = 1;
  const transducer_handsfree = 2;
  const transducer_all_pairs = 0x3f;

  var WebRTC = {
    on_connect: function(chan) {
      var id = chan.topic.substr(5, 100)
      console.log('on_connect...', id)
      this.context = new UcxUcc.AudioContext();
      this.stream_hs = null;
      this.gain_hf = null;
      this.gain_hs = null;
      this.initialized = false;
      this.remoteAudio = document.querySelector('#audio');
      this.id = id;
      this.localConnection = null;
      this.connectedUser = null;
      this.stream = null;
      this.has_headset = false;
      this.debug = true;
      this.chan = chan;
      UcxUcc.DeviceManager.set_webrtc(this)
    },
    send: function(message) {
      if (this.connectedUser) {
        message.name = this.connectedUser;
      }
      if (this.debug)
        console.log('pushing for ' + this.id, message)
      this.chan.push("webrtc", message)
    },
    set_transducer: function(pair_id) {
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
          if (this.debug) console.log('set_transducer all')
          this.enable_headset_gain(true)
          this.enable_handsfree_gain(true)
          break
      }
    },
    enable_headset_gain: function(enable) {
      if (this.gain_hs) {
        let enabled = 0
        if (enable) enabled = 1
        this.gain_hs.gain.value = enabled
      }
    },
    enable_handsfree_gain: function(enable) {
      if (this.gain_hf) {
        let enabled = 0
        if (enable) enabled = 1
        this.gain_hf.gain.value = enabled
      }
    },
    stop_transducer: function(pair_id) {
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
    },
    onOffer: function(offer, name) {
      if (offer.to == "" || offer.from == "") {
        if (this.debug)
          console.log('onOffer error ', offer, 'with name ', name)
        return
      }
      if (this.debug) console.log('RTC: onOffer', offer)
      this.connectedUser = name
      console.log('onOffer this', this)

      this.localConnection.setRemoteDescription(new RTCSessionDescription(offer), function() {
        if (this.debug) console.log('trying create answer')
        this.create_answer()
      }, function(error) {
        console.warn('setRemoteDescription error ', error)
      })
    },
    create_answer: function() {
      if (this.debug) console.log("RTC: create_answer")
      this.localConnection.createAnswer(function (answer) {
        this.localConnection.setLocalDescription(answer);
        if (this.debug) console.log('sending the answer', answer)
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
    },
    onAnswer: function(answer) {
      if (this.debug) console.log("RTC: onAnswer", answer)
      console.log('onAnswer this', this)
      this.localConnection.setRemoteDescription(new RTCSessionDescription(answer));
    },
    onCandidate: function(candidate) {
      var ice_candidate = new RTCIceCandidate(candidate)
      if (this.debug) {
        console.log("RTC: onCandidate", candidate, ice_candidate)
        console.log("RTC: onCandidate remoteConnection", this.localConnection)
      }
      this.localConnection.addIceCandidate(ice_candidate);
    },
    onLeave: function() {
      if (this.debug) console.log('RTC: onLeave')
      if (this.localConnection) {
        this.localConnection.close();
        this.localConnection.onicecandidate = null;
        this.localConnection.onaddstream = null;
        this.connectedUser = null;
        if (this.remoteAudio) {
          this.remoteAudio.srcObject = undefined;
        }
        this.setupPeerConnection(this.stream);
      }
    },
    connectionClosed: function() {
      return this.localConnection.signalingState === "closed"
    },
    startConnection: function() {
      if (this.initialized) return

      this.resetConnection()
    },
    resetConnection: function() {
      var current = UcxUcc.Mscs.WebRTC;

      this.has_headset = UcxUcc.DeviceManager.has_headset_device()

      this.initialized = true

      if (UcxUcc.hasUserMedia()) {
        let contraints_hs = {
          video: false,
          audio: {
            optional: [{sourceId: UcxUcc.DeviceManager.get_device("headset_input_id")}]
          }
        }
        let contraints_hf = {
          video: false,
          audio: {
            optional: [{sourceId: UcxUcc.DeviceManager.get_device("handsfree_input_id")}]
          }
        }

        if (this.has_headset) {
          if (this.debug) console.log('getUserMedia for headset')
          navigator.getUserMedia(contraints_hs, function (myStream) {
            current.stream_hs = myStream;
          }, function(error) {
            console.error('hf:', error);
          })
        } else {
          if (this.debug) console.log('skipping getUserMedia for headset')
        }

        navigator.getUserMedia(contraints_hf, function (myStream) {
          var handsfree = current.context.createMediaStreamSource(myStream)
          var mixedOutput = current.context.createMediaStreamDestination()

          window.gain_hf = current.gain_hf = current.context.createGain()

          current.gain_hf.gain.value = 0
          handsfree.connect(current.gain_hf)
          current.gain_hf.connect(mixedOutput)

          if (current.has_headset) {
            if (current.debug) console.log('found headset. stream_hs:', current.stream_hs)
            var headset = current.context.createMediaStreamSource(current.stream_hs)
            window.gain_hs = current.gain_hs = current.context.createGain()
            current.gain_hs.gain.value = 1
            headset.connect(current.gain_hs)
            current.gain_hs.connect(mixedOutput)
          }

          current.stream = mixedOutput.stream
          window.stream = current.stream

          if (UcxUcc.hasRTCPeerConnection()) {
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
    },
    getpeer: function() {
      return this.remoteConnection;
    },
    setupPeerConnection: function(stream) {
      var current = UcxUcc.Mscs.WebRTC;
      if (this.debug) console.log("RTC: setupPeerConnection", stream)
      var configuration = {
        // TODO: Need to use the configured stun servers
        // "iceServers": [{ "url": "stun:" + mscs.stunaddr }]
        "iceServers": [{ "url": "stun:" + 'stun.l.google.com:19302'}]
      };
      this.localConnection = new RTCPeerConnection(configuration);

      // Setup stream listening
      this.localConnection.addStream(stream);

      this.localConnection.onaddstream = function (e) {
        if (this.debug) console.log('onaddstream:', e.stream)
        // current.remoteAudio.srcObject = e.stream;
        current.remoteAudio.src = window.URL.createObjectURL(e.stream);
        UcxUcc.DeviceManager.update_transducer()
      };

      // Setup ice handling
      this.localConnection.onicecandidate = function (event) {
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
    },
    startPeerConnection: function(user) {
      var current = UcxUcc.Mscs.WebRTC
      if (this.debug) console.log("RTC: startPeerConnection", user)
      this.connectedUser = user

      // Begin the offer
      this.localConnection.createOffer(function (offer) {
        current.send({
          type: "offer",
          offer: offer
        });
        current.localConnection.setLocalDescription(offer);
      }, function (error) {
        current.send({
          type: "error",
          message: "startPeerConnection error" + error
        })
        console.error("An error has occurred.", error);
      });
    }
  };

  window.UcxUcc.Mscs.WebRTC = WebRTC;
})();
