(function() {
  const sptone_select = [[], [250], [333], [333, 250], [500], [500, 250], [500, 333], [500,333, 250],
                        [667], [667, 250], [667, 333], [667, 333, 250], [667, 500], [667, 500, 250],
                        [667, 500, 333], [667, 500, 333, 250], [1000], [1000, 250], [1000, 333],
                        [1000, 333, 250], [1000, 500], [1000, 500, 250], [1000, 500, 333],
                        [1000, 500, 333, 250], [1000, 667], [1000, 667, 250], [1000, 667, 333],
                        [1000, 667, 333, 250], [1000, 667, 500], [1000, 667, 500, 250],
                        [1000, 667, 500, 333], [1000, 667, 500, 333, 250]]

  const MAX_TONE_SELECT = 32;

  var SpecialTone = {
    specialTone: undefined,
    setup: function() {
      this.destination = this.context.createMediaStreamDestination();
      this.context = UcxUcc.Mdse.Paging.context;
    },
    get_vol_step_factor: function() {
      return(this.specialTone.vol_step_factor());
    },
    set_headset_output: function() {
      if (typeof this.specialTone != undefined)
        this.specialTone.default_destination = false
    },
    tone_configuration: function(msg) {
      this.specialTone = new Tone(context);
      this.specialTone.volume_steps = msg.tone_volume_steps;

      var sp = document.getElementById("audio-alerting");

      sp.oncanplay = function() {
        if (!this.specialTone.default_destination)
          sp.play()
      }

      if (msg.special_tone_select > 0 && msg.special_tone_select < MAX_TONE_SELECT)
      {
        this.specialTone.set_frequencies(sptone_select[msg.special_tone_select]);
      }
      else {
        console.warn(' Unsupported special tone select: ', msg.special_tone_select)
      }
    },
    start_tone: function(msg) {
      this.specialTone.startTone(msg.attenuated)
    },
    stop_tone: function() {
      this.specialTone.stopTone()
    }
  };

  $(document).ready(function() {
    SpecialTone.setup();
    UcxUcc.Mscs.SpecialTone = SpecialTone;
  });

  function Tone(context) {
    this.context = context;
    this.status = 0;
    this.freqs = [];
    this.oscs = [];
    this.gainNode = [];
    this.volume_steps = 0;
    this.cadence = [];
    this.loop = true;
    this.default_destination = true
    this.destination = destination
  }

  Tone.prototype.setup = function() {
    let device = UcxUcc.DeviceManager;

    this.gainNode = this.context.createGain();
    this.gainNode.gain.value = device.get_audio_ctrl_volume(); //0.15;
    for (var i = 0; i < this.freqs.length; i++) {
      this.oscs[i] = context.createOscillator();
      this.oscs[i].frequency.value = this.freqs[i];
      this.oscs[i].connect(this.gainNode);
    }
    if (this.default_destination)
      this.gainNode.connect(this.context.destination);
    else
      this.gainNode.connect(this.destination);
  }

  Tone.prototype.set_frequencies = function(frequency) {
    this.freqs = frequency
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

  Tone.prototype.startTone = function(attenuated) {
    this.start();
    if (attenuated)
    {
      var vol_factor = 2 * this.vol_step_factor();
      if(this.gainNode.gain.value > vol_factor) {
        this.gainNode.gain.value = this.gainNode.gain.value - vol_factor;
      }
    }

    for (var i = 0; i < this.freqs.length; i++) {
      // Ramp up the gain so we can hear the sound.
      // We can ramp smoothly to the desired value.
      this.gainNode.gain.cancelScheduledValues(this.context.currentTime);
      // Anchor beginning of ramp at current value.
      this.gainNode.gain.setValueAtTime(this.gainNode.gain.value, this.context.currentTime);
      this.gainNode.gain.linearRampToValueAtTime(0.5, this.context.currentTime + 0.1);
    }
  }

  Tone.prototype.stopTone = function() {
    this.stop();
    for (var i = 0; i < this.freqs.length; i++) {
      this.gainNode.gain.cancelScheduledValues(this.context.currentTime);
      this.gainNode.gain.setValueAtTime(this.gainNode.gain.value, this.context.currentTime);
      this.gainNode.gain.linearRampToValueAtTime(0.0, this.context.currentTime + 0.1);
    }
  }

  Tone.prototype.vol_step_factor = function() {
    return(1/(this.volume_steps - 1));
  }

})();
