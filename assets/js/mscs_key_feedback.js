(function() {
  console.log('loading mscs_key_feedback');

  const tone_click = [338, 997, 1660, 2340, 3000, 3659];
  const tone_dtmf1 = [697,770,852,941];
  const tone_dtmf2 = [1209,1336,1477,1633];
  const tone_dtmf = [[3,1],[0,0],[0,1],[0,2],[1,0],[1,1],[1,2],[2,0],[2,1],[2,2],[3,0],[3,2],[0,3],[1,3],[2,3],[3,3]];
  const osc_type = 'sine';
  const gain_vol = 0.01;
  const audio_device = 'audio-keypad';

  const ring_sz = 10;

  var ring = [];
  var oscs = [];
  var sz;

  function Beep(context, freqs) {
    this.context = context;
    this.freqs = freqs;
    this.oscs = [];
    this.sz = freqs.length;
  }

  Beep.prototype.start = function(duration) {
    let i = 0
    let startTime = this.context.currentTime

    this.destination = this.context.createMediaStreamDestination();
    this.audio = document.querySelector('#audio').src
    this.gainNode = this.context.createGain()
    this.gainNode.gain.value = gain_vol
    for (i = 0; i < this.sz; i++) {
      this.oscs[i] = this.context.createOscillator()
      this.oscs[i].type = osc_type
      this.oscs[i].frequency.value = this.freqs[i]
      this.oscs[i].connect(this.gainNode)
    }
    this.gainNode.connect(this.destination)
    this.gainNode.gain.setValueAtTime(gain_vol, startTime + duration - 0.010)
    this.gainNode.gain.linearRampToValueAtTime(0, startTime + duration)

    let dev = document.getElementById(audio_device);

    dev.srcObject = this.destination.stream
    dev.play()

    for (i = 0; i < this.sz; i++) {
      this.oscs[i].start(startTime)
    }
    for (i = 0; i < this.sz; i++) {
      this.oscs[i].stop(startTime + duration)
    }
  };

  function Feedback() {
    this.context = new UcxUcc.AudioContext();
    this.mode = 'none';
    this.freqs = [];
    this.oscs = [];
    this.gainNode = [];
  };

  Feedback.prototype.set_mode = function(mode){
    this.mode = mode;
  };
  Feedback.prototype.vol_press = function(current_device) {
    if (current_device) {
      this.start_click();
    }
  };
  Feedback.prototype.key_press = function(key) {
    switch(this.mode) {
      case "click":
        this.start_click();
        break;
      case "dtmf":
        this.start_dtmf(key);
        break;
    }
  };

  Feedback.prototype.start_click = function() {
    let beep = new Beep(this.context, tone_click);
    beep.start(0.09)
  };

  Feedback.prototype.start_dtmf = function(key) {
    let beep = new Beep(this.context, this.get_dtmf_tone(key));
    beep.start(0.2)
  };

  Feedback.prototype.get_dtmf_tone = function(digit) {
    let index = 0;

    if (digit >= '0' && digit <= '9') {
      index = digit - '0';
    } else if (digit ==  '*') {
      index = 10;
    } else if (digit == '#') {
      index = 11;
    } else {
      return 0;
    }

    let indexes = tone_dtmf[index];
    return [tone_dtmf1[indexes[0]], tone_dtmf2[indexes[1]]];
  };

  Feedback.prototype.set_volume = function(volume) {
    document.getElementById(audio_device).volume = volume;
  };

  window.UcxUcc.Mscs.Feedback = {
    create: function() {
      window.UcxUcc.Mscs.feedback = new Feedback();
    },
    set_volume: function(volume) {
      document.getElementById(audio_device).volume = volume;
    }
  };

})();
