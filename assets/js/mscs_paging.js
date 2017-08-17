(function() {
  const preset_paging_freqs = [[333, 500, 667], [667, 500, 333], [333, 500, 333], [667, 333, 667],
                               [333, 500, 667], [500, 250, 500], [250, 500, 250]]
  const preset_paging_cad = [[250, 125, 250, 125, 250, 0], [250, 63, 250, 63, 250, 0],
                             [313, 188, 313, 188, 313, 0], [375, 125, 375, 125, 375, 0],
                             [125, 13, 125, 13, 125, 0], [188, 13, 188, 13, 188, 0],
                             [250, 0, 250, 0, 250, 0]]
  const paging_freqs = [[], [250], [333], [333, 250], [500], [500, 250], [500, 333], [500,333, 250],
                        [667], [667, 250], [667, 333], [667, 333, 250], [667, 500], [667, 500, 250],
                        [667, 500, 333], [667, 500, 333, 250], [1000], [1000, 250], [1000, 333],
                        [1000, 333, 250], [1000, 500], [1000, 500, 250], [1000, 500, 333],
                        [1000, 500, 333, 250], [1000, 667], [1000, 667, 250], [1000, 667, 333],
                        [1000, 667, 333, 250], [1000, 667, 500], [1000, 667, 500, 250],
                        [1000, 667, 500, 333], [1000, 667, 500, 333, 250]]

  var Paging = {
    pagingTone: undefined,
    context: new UcxUcc.AudioContext(),
    setup: function() {
      this.destination = this.context.createMediaStreamDestination();
    },
    set_headset_output: function() {
      if (typeof this.pagingTone != undefined)
        this.pagingTone.default_destination = false;
    },
    tone_cadence_download: function(msg) {
      var freq1 = [];
      var freq2 = [];
      var cad1 = [];
      var cad2 = [];
      var on1 = 0;
      var on2 = 0;
      var off1 = 0;
      var off2 = 0;

      this.pagingTone = new Tone(this.context);

      function tone_freqs(x) {
        if (x > 0 && x < 32)
           return paging_freqs[x];
        else
           console.log ('Undefined Paging Tone select:', x);
      }
      freq1 = tone_freqs(msg.paging_tone_select_1);
      freq2 = tone_freqs(msg.paging_tone_select_2);

      // 8 = 100ms, 16 = 200ms, 24 = 300ms
      function cal_on_off(x) {
        if (x % 8 == 0)
          return (x * 100)/8;
        else
          return x;
      }
      on1 = cal_on_off(msg.on_time_1);
      off1 = cal_on_off(msg.off_time_1);
      on2 = cal_on_off(msg.on_time_2);
      off2 = cal_on_off(msg.off_time_2);
      cad1 = [on1, off1];
      cad2 = [on2, off2];

      this.dl_freqs = freq1.concat(freq2);
      this.dl_cadence = cad1.concat(cad2);
      if (mscs.debug)
        console.log ('dl_freqs, dl_cadence ', this.dl_freqs, this.dl_cadence)
    },
    tone_configuration: function(msg) {
      var aud = document.getElementById("audio-alerting")
      aud.oncanplay = function() {
        if (!pagingTone.default_destination)
          aud.play()
      }

      this.pagingTone.set_volume_steps(msg.tone_volume_steps);

      if (msg.cadence_select < 7)
      {
        this.pagingTone.set_frequencies(preset_paging_freqs[msg.cadence_select]);
        this.pagingTone.set_cadence(preset_paging_cad[msg.cadence_select]);
      }
      else if (msg.cadence_select == 7) {
        this.pagingTone.set_frequencies(this.dl_cadence);
        this.pagingTone.set_cadence(this.dl_cadence);
      }
      else {
        console.warn('Unsupported paging cadence select: ', msg.cadence_select)
      }
    },
    startTone: function(msg) {
        this.pagingTone.startRinging(msg.attenuated);
    },
    stopTone: function() {
      if (this.pagingTone && this.pagingTone.status === 1) {
        this.pagingTone.stopRinging();
      }
    },
    get_vol_step_factor: function() {
      return(this.pagingTone.vol_step_factor());
    }
  };

  $(document).ready(function() {
    Paging.setup();
    window.UcxUcc.Mscs.Paging = Paging;
  });



  function Tone(context) {
    this.context = context;
    this.status = 0;
    this.freqs = [];
    this.oscs = [];
    this.gainNode = [];
    this.vGainNode = [];
    this.volume_steps = 0;
    this.ringerLFOBuffer = [];
    this.ringerLFOSource = [];
    this.cadence = [];
    this.dl_freqs = [];
    this.dl_cadence = [];
    this.loop = true;
    this.default_destination = true
    this.destination = destination
  }

  Tone.prototype.set_volume_steps = function(volume_steps) {
    this.volume_steps = volume_steps
  }

  Tone.prototype.set_frequencies = function(freqs) {
    this.freqs = freqs
  }

  Tone.prototype.set_cadence = function(cadence) {
    this.cadence = cadence
  }

  Tone.prototype.setup = function() {
    let device = UcxUcc.DeviceManager;

    this.filter = this.context.createBiquadFilter();
    this.filter.type = "peaking";
    this.filter.Q.value = 100;
    this.filter.gain.value = 6;
    this.filter.frequency.value = 3500;

    this.vGainNode = this.context.createGain();
    this.vGainNode.gain.value = device.get_audio_ctrl_volume();

    for (var i = 0; i < this.freqs.length; i++) {
      this.oscs[i] = this.context.createOscillator();
      this.oscs[i].frequency.value = this.freqs[i];
      this.gainNode[i] = this.context.createGain();
      this.gainNode[i].gain.value = 0.15;
      this.oscs[i].connect(this.gainNode[i]);
      this.gainNode[i].connect(this.vGainNode);
    }
    this.vGainNode.connect(this.filter);
    if (this.default_destination) {
      this.filter.connect(this.context.destination);
    }
    else {
      this.filter.connect(this.destination);
    }
  }

  Tone.prototype.start = function() {
    this.setup();
    for (var i = 0; i < this.freqs.length; i++) {
      this.oscs[i].start(0);
    }
    this.status = 1;
  }

  Tone.prototype.stop = function() {
    for (var i = 0; i < this.freqs.length; i++) {
      this.oscs[i].stop(0);
    }
    this.status = 0;
  }

  Tone.prototype.createRingerLFO = function(index) {
    let channels = 1;
    let sampleRate = this.context.sampleRate;
    let c_on1 = 0
    let c_off1 = 0
    let c_on2 = 0
    let c_off2 = 0
    let c_on3 = 0

    switch(this.cadence.length) {
      case 6:
        c_on1 = this.cadence[0] * sampleRate
        c_off1 = this.cadence[1] * sampleRate + c_on1
        c_on2 = this.cadence[2] * sampleRate + c_off1
        c_off2 = this.cadence[3] * sampleRate + c_on2
        c_on3 = this.cadence[4] * sampleRate + c_off2
        this.loop = false
        break;
      case 4:
        c_on1 = this.cadence[0] * sampleRate
        c_off1 = this.cadence[1] * sampleRate + c_on1
        c_on2 = this.cadence[2] * sampleRate + c_off1
        c_off2 = this.cadence[3] * sampleRate + c_on2
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

    let frameCount = sampleRate * frameLength/1000;
    let myArrayBuffer = this.context.createBuffer(channels, frameCount, sampleRate);

    // getChannelData allows us to access and edit the buffer data and change.
    let bufferData = myArrayBuffer.getChannelData(0);

    for (var i = 0; i < frameCount; i++) {
      if (((i < c_on1) || (i > c_off1 && i < c_on2) ) || (i > c_off2 && i < c_on3)) {
        var rem = i % sampleRate
        if (rem < sampleRate)
          bufferData[i] = 0.25
        else
          bufferData[i] = 0
      }
    }
    this.ringerLFOBuffer[index] = myArrayBuffer;
  }

  Tone.prototype.vol_step_factor = function() {
    return(1/(this.volume_steps - 1));
  }

  Tone.prototype.startRinging = function(attenuated) {
    this.start();
    if (attenuated)
    {
      var vol_factor = 2 * this.vol_step_factor();
      if(this.vGainNode.gain.value > vol_factor) {
        this.vGainNode.gain.value = this.vGainNode.gain.value - vol_factor;
      }
    }
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
  }

  Tone.prototype.stopRinging = function() {
    this.stop();
    for (var i = 0; i < this.freqs.length; i++) {
      this.ringerLFOSource[i].stop(0);
    }
  }
})();
