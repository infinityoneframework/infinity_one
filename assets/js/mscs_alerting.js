(function() {
  var AudioContext = window.AudioContext ||
                     window.webkitAudioContext ||
                     window.mozAudioContext;
  var alertingTone;
  var context = new AudioContext();

  const cadenceList = [[2, 4], [0.5, 0.3, 1.2, 4], [0.7, 0.5, 0.7, 4], [0.5]]

  var Alerting = {
    alertingTone: undefined,
    context: context,
    destination: context.createMediaStreamDestination(),
    alerting_audio_ctrl: undefined,
    mwi: {}, //cad_on: 2000, cad_off: 4000, t_on: 70, t_off: 30}
    get_alerting_rx_volume_parms: function() {
      let alerting_apb = 0x10;
      var ceiling = 0;
      var floor = 0;
      var apb_def_rx_vol = Math.floor(this.alertingTone.rx_volume()/this.alertingTone.vol_step_factor());
      var up_down = apb_def_rx_vol/(this.alertingTone.volume_steps-1);
      switch (up_down) {
        case 0:
          floor = 1;
          break;
        case 1:
          ceiling = 1;
          break;
        default:
          break;
      }
      var rx_volume = {active_apb: alerting_apb,
        ceiling: ceiling,
        floor: floor,
        apb_def_rx_vol: apb_def_rx_vol,
        vol_range: this.alertingTone.volume_steps-1};
      return (rx_volume);
    },
    volume_up: function() {
      this.alertingTone.volume_up()
    },
    volume_down: function() {
      this.alertingTone.volume_down()
    },
    get_vol_step_factor: function() {
      return(this.alertingTone.vol_step_factor());
    },
    set_headset_output: function() {
      if (typeof this.alertingTone != undefined)
        this.alertingTone.default_destination = false
    },
    alerting_tone_configuration: function(msg) {
      console.log('alerting_tone_configuration', msg)

      if (typeof this.alertingTone == 'undefined') {
        this.alertingTone = new Tone(this, this.context)
        console.log('alertingTone', this.alertingTone)
        // window.mscs.alertingTone = alertingTone
        var aud = document.getElementById("audio-alerting")
        aud.oncanplay = () => {
          if (!this.alertingTone.default_destination)
            aud.play()
        }
      }
      if (this.alertingTone.status != 1) {
        this.alertingTone.setupCadences(msg)
        setup_mwi(this)
      }
    },
    set_mwi: function(state) {
      this.mwi.state = state
      mwi_led_update(this, state)
    },
    startAlerting: function(msg) {
      console.log('startAlerting', this)
      this.alertingTone.startRinging(msg.attenuated);
    },
    stopAlerting: function() {
      if (this.alertingTone && this.alertingTone.status === 1) {
        this.alertingTone.stopRinging();
        // $('#audio-alerting')[0].pause()
      }
    }
  };

  function Tone(alerting, context) {
    console.log('Tone', alerting, context);
    this.alerting = alerting;
    this.context = context;
    this.status = 0;
    this.warble = [];
    this.freqs = [];
    this.oscs = [];
    this.gainNode = [];
    this.vGainNode = [];
    this.volume_steps = 0;
    this.ringerLFOBuffer = [];
    this.ringerLFOSource = [];
    this.cadence = [];
    this.loop = true;
    this.default_destination = true
    this.destination = alerting.destination
    this.volume = 0.7
    this.volume_steps = 8
    $('#audio-alerting')[0].srcObject = this.destination.stream
  }

  Tone.prototype.setupCadences = function(msg) {
    console.log('setupCadences context', this.context)
    if (this.context.status != 1) {
      let cadenceSelect = cadenceList[msg.cadence_select];
      let alertingTone = this;

      alertingTone.cadence = cadenceSelect;
      alertingTone.warbler_select = msg.warbler_select;
      alertingTone.volume_steps = msg.tone_volume_steps;

      switch (msg.warbler_select)
      {
        case 0:
          alertingTone.set_frequencies(0, [670, 2000, 3300]);
          alertingTone.set_frequencies(1, [500, 1500, 2500, 3500]);
          alertingTone.set_warble(0, 0.07, 0.03, 0, 0.25, 0.1);
          alertingTone.set_warble(1, 0.07, 0.03, 0.04, 0.25, 0.1);
          break;
        case 1:
          alertingTone.set_frequencies(0, [340, 1000, 1670, 2340, 3000])
          alertingTone.set_frequencies(1, [250, 750, 1260, 1750, 2250, 2760, 3250])
          alertingTone.set_warble(0, 0.06, 0.04, 0, 0.25, 0.1);
          alertingTone.set_warble(1, 0.06, 0.04, 0.06, 0.25, 0.1);
          break;
        case 2:
          alertingTone.set_frequencies(0, [330, 670, 1000, 1670, 2000, 2330, 3000, 3350]);
          alertingTone.set_frequencies(1, [500, 1500, 2500]);
          alertingTone.set_warble(0, 0.13, 0.05, 0, 0.25, 0.1);
          alertingTone.set_warble(1, 0.13, 0.05, 0.09, 0.25, 0.1);
          break;
        case 3:
          alertingTone.set_frequencies(0, [340, 1000, 1670, 2340, 3000]);
          alertingTone.set_frequencies(1, [500, 1500, 2500]);
          alertingTone.set_frequencies(2, [660, 2000, 3340]);
          alertingTone.set_warble(0, 0.2, 0.1, 0, 0.25, 0.1);
          alertingTone.set_warble(1, 0.15, 0.15, 0.15, 0.25, 0.1);
          alertingTone.set_warble(2, 0.15, 0.15, 0.2, 0.25, 0.1);
          break;
        case 4:
          alertingTone.set_frequencies(0, [500, 1500, 2500, 3500]);
          alertingTone.set_frequencies(1, [670, 2000, 3340]);
          alertingTone.set_warble(0, 0.15, 0.05, 0, 0.25, 0.0);
          alertingTone.set_warble(1, 0.15, 0.05, 0.1, 0.25, 0.0);
          break;
        case 5:
          alertingTone.set_frequencies(0, [500, 1500, 2500, 3500]);
          alertingTone.set_frequencies(1, [720, 2000, 3340]);
          alertingTone.set_warble(0, 0.46, 0.36, 0, 0.25, 0.0);
          alertingTone.set_warble(1, 0.46, 0.36, 0.4, 0.25, 0.0);
          break;
        case 6:
          alertingTone.set_frequencies(0, [250, 760, 1250, 1750, 2250, 2750, 3260]);
          alertingTone.set_frequencies(1, [340, 1000, 1670, 2330, 3000]);
          alertingTone.set_warble(0, 0.15, 0.06, 0, 0.25, 0.0);
          alertingTone.set_warble(1, 0.15, 0.06, 0.1, 0.25, 0.0);
          break;
        case 7:
          alertingTone.set_frequencies(0, [250, 750, 1250, 1750, 2250, 2750, 3250]);
          alertingTone.set_frequencies(1, [340, 1000, 1670, 1340, 3000, 3670]);
          alertingTone.set_warble(0, 0.45, 0.36, 0, 0.45, 0.0);
          alertingTone.set_warble(1, 0.45, 0.36, 0.4, 0.45, 0.0);
          break;
        default:
          break;
      }
    }
  }

  Tone.prototype.change_gain = function(value, dir) {
        this.set_gain(value, dir);
  }

  Tone.prototype.set_frequencies = function(index, freqs) {
    this.freqs[index] = freqs
  }
  Tone.prototype.set_warble = function(index, t_on, t_off, t_delay, on_gain, off_gain) {
    this.warble[index] = {}
    this.warble[index].t_on = t_on
    this.warble[index].t_off = t_off
    this.warble[index].t_delay = t_delay
    this.warble[index].on_gain = on_gain
    this.warble[index].off_gain = off_gain
  }

  Tone.prototype.volume_range = function() {
    return(this.volume_steps);
  }
  Tone.prototype.rx_volume = function() {
    return(this.volume);
  }

  Tone.prototype.vol_step_factor = function() {
    var step_factor = 1 / (this.volume_steps - 1)
    return(step_factor);
  }

  Tone.prototype.volume_up = function() {
    let new_gain = 1.0

    if(this.vGainNode.gain.value + this.vol_step_factor() < 1.0) {
      new_gain = this.vGainNode.gain.value + this.vol_step_factor()
    }
    this.vGainNode.gain.value = this.volume = new_gain
  }

  Tone.prototype.volume_down = function() {
    let new_gain = this.vol_step_factor()
    if(this.vGainNode.gain.value - this.vol_step_factor() > this.vol_step_factor()) {
      new_gain = this.vGainNode.gain.value - this.vol_step_factor()
    }
    this.vGainNode.gain.value = this.volume = new_gain
  }

  Tone.prototype.setup = function() {

      for (var i = 0; i < this.freqs.length; i++) {
        this.oscs[i] = [];
        for (var j = 0; j < this.freqs[i].length; j++) {
          this.oscs[i][j] = context.createOscillator();
          this.oscs[i][j].frequency.value = this.freqs[i][j];
        }
        this.gainNode[i] = this.context.createGain();
        this.gainNode[i].gain.value = 0.15;
      }
      this.vGainNode = this.context.createGain();
      this.volume = UcxUcc.DeviceManager.get_audio_ctrl_volume();

      if (typeof this.volume === "undefined")
        this.volume = 0.7;

      this.vGainNode.gain.value = 0;

      this.filter = this.context.createBiquadFilter();
      this.filter.type = "peaking";
      this.filter.Q.value = 100;
      this.filter.gain.value = 6;
      this.filter.frequency.value = 3500;

      for (var i = 0; i < this.freqs.length; i++) {
        for (var j = 0; j < this.freqs[i].length; j++) {
          this.oscs[i][j].connect(this.gainNode[i]);
        }
        this.gainNode[i].connect(this.vGainNode);
      }
      this.vGainNode.connect(this.filter);

      if (this.default_destination)
        this.filter.connect(this.context.destination);
      else
        this.filter.connect(this.destination);
  }

  Tone.prototype.start = function() {
    this.setup();
    for (var i = 0; i < this.freqs.length; i++) {
      for (var j = 0; j < this.freqs[i].length; j++) {
        this.oscs[i][j].start(0);
      }
    }
  }

  Tone.prototype.stop = function() {
    for (var i = 0; i < this.freqs.length; i++) {
      for (var j = 0; j < this.freqs[i].length; j++) {
        this.oscs[i][j].stop(0);
      }
    }
    this.status = 0;
  }

  Tone.prototype.createRingerLFO = function(index) {
    let channels = 1;
    let sampleRate = this.context.sampleRate;

    const warble = this.warble[index];

    let samples_per_cycle = sampleRate * (warble.t_on + warble.t_off);
    let on_count = sampleRate * warble.t_on;
    let off_count = sampleRate * warble.t_off;
    let delay_count = sampleRate * warble.t_delay;
    let c_on1 = 0
    let c_off1 = 0
    let c_on2 = 0
    let c_off2 = 0

    switch(this.cadence.length) {
      case 2:
        c_on1 = this.cadence[0] * sampleRate
        c_off1 = this.cadence[1] * sampleRate + c_on1
        break;
      case 4:
        c_on1 = this.cadence[0] * sampleRate
        c_off1 = this.cadence[1] * sampleRate + c_on1
        c_on2 = this.cadence[2] * sampleRate + c_off1
        break;
      case 1:
        // one shot
        c_on1 = this.cadence[0] * sampleRate
        this.loop = false
        break;
      default:
        console.error('createRingerLFO: Invalid cadence length', this.cadence)
        break;
    }
    let frameLength = 0

    this.cadence.forEach(function(x) {
      frameLength += x
    })

    let frameCount = sampleRate * frameLength;
    let myArrayBuffer = this.context.createBuffer(channels, frameCount, sampleRate);

    // getChannelData allows us to access and edit the buffer data and change.
    let bufferData = myArrayBuffer.getChannelData(0);

    for (var i = delay_count; i < frameCount; i++) {
      if ((i < c_on1) || ((i >= c_off1) && (i < c_on2))) {
        var rem = i % samples_per_cycle
        if ((rem >= delay_count) && (rem < (on_count + delay_count)))
          bufferData[i] = warble.on_gain
        else
          bufferData[i] = warble.off_gain
      }
    }
    this.ringerLFOBuffer[index] = myArrayBuffer;
  }

  Tone.prototype.startRinging = function(attenuated) {
    if (typeof this.volume == 'undefined') {
      console.error('undefined volume', this)
      this.volume = 0.7
    }
    if (this.status != 1) {
      this.start();
      // set our gain node to 0, because the LFO is calibrated to this level
      for (var i = 0; i < this.freqs.length; i++) {
        this.gainNode[i].gain.value = 0;
        this.createRingerLFO(i);
        this.ringerLFOSource[i] = this.context.createBufferSource();
        this.ringerLFOSource[i].buffer = this.ringerLFOBuffer[i];
        this.ringerLFOSource[i].loop = this.loop;
        this.ringerLFOSource[i].connect(this.gainNode[i].gain);
        this.ringerLFOSource[i].start(0);
      }
      this.status = 1;
      alert_mwi_on()
    }
    if (attenuated)
    {
      let double_step = (2 * this.vol_step_factor())
      let vol = 0

      if (this.volume == double_step)
        vol = this.volume - this.vol_step_factor()
      else
        vol = this.volume - double_step

      if (vol < 0) vol = 0
      this.vGainNode.gain.value = vol
    } else {
      this.vGainNode.gain.value = this.volume
    }
  }

  Tone.prototype.stopRinging = function() {
    this.stop();
    for (var i = 0; i < this.freqs.length; i++) {
      this.ringerLFOSource[i].stop(0);
    }
    // alert_mwi_off(this.alerting)
  }

  function setup_mwi(alerting) {
    console.log('setup_mwi alerting', alerting)
    // alerting.mwi.cad_on = alerting.alertingTone.cadence[0] * 1000
    // alerting.mwi.cad_off = alerting.alertingTone.cadence[1] * 1000
    // alerting.mwi.t_on = alerting.alertingTone.warble[0].t_on * 1000
    // alerting.mwi.t_off = alerting.alertingTone.warble[0].t_on * 1000
    // alerting.mwi.loop = alerting.alertingTone.loop
  }

  function alert_mwi_on(alerting) {
    // mwi_cad_start(alerting)
  }

  function alert_mwi_off(alerting) {
    // clearTimeout(alerting.mwi.warble_timer)
    // clearTimeout(alerting.mwi.cad_timer)
    // mwi_led_update(alerting.mwi.state)
  }

  function mwi_cad_start(alerting) {
    // alerting.mwi.cad_timer = setTimeout(function() {
    //   mwi_cad_stop(alerting)
    // }, alerting.mwi.cad_on)
    // mwi_warble_on(alerting)
  }
  function mwi_cad_stop(alerting) {
    // clearTimeout(alerting.mwi.warble_timer)
    // mwi_led_update(alerting.mwi.state)
    // if (alerting.mwi.loop) {
    //   alerting.mwi.cad_timer = setTimeout(function() {
    //     mwi_cad_start(alerting)
    //   }, alerting.mwi.cad_off)
    // }
  }
  function mwi_warble_on(alerting) {
    // mwi_led_update("on")
    // mwi.warble_timer = setTimeout(function() {
    //   mwi_warble_off(alerting)
    // }, alerting.mwi.t_on)
  }
  function mwi_warble_off(alerting) {
    // mwi_led_update("off")
    // alerting.mwi.warble_timer = setTimeout(function() {
    //   mwi_warble_on(alerting)
    // }, alerting.mwi.t_off)
  }

  function mwi_led_update(alerting, state) {
    let key = $("#fk-msg_waiting")
    switch(state) {
      case "on":
        key.removeClass("off")
        key.removeClass("process-red-mwi-flash")
        key.addClass("process-red")
        break;
      case "off":
        key.addClass("off")
        key.removeClass("process-red-mwi-flash")
        key.addClass("process-red")
        break;
      case "flash":
        key.removeClass("off")
        key.removeClass("process-red")
        key.addClass("process-red-mwi-flash")
        break;
      default:
        console.warn("key:led_update, state not handled", state)
    }
  }

  window.Mscs.Tone = Tone;
  window.Mscs.Alerting = Alerting;
})();
