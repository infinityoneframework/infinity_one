(function() {
  console.log('loading tone_generator');

  if (InfinityOne.trace_startup) { console.log('loading tone_generator', InfinityOne); }

  var ToneGenerator = {
    debug: true,
    audioContext: createAudioContext(),
    oscillator: [],
    amp: [],
    frequencies: [],
    stream_tone_ids: [],
    cadences: [],
    cadence_timeouts: [],
    destination: undefined,
    control: undefined,
    initStart: function() {
      var ctrl = this.control; //
      this.destination = this.audioContext.createMediaStreamDestination();
      if (ctrl) {
        ctrl.srcObject = this.destination.stream
      }
    },
    // Set the frequency of the oscillator and start it running.
    startTone: function(toneId, frequency) {
      initAudio(this, toneId);
      this.oscillator[toneId].start(0);
    },
    stopTone: function(toneId) {
      if (this.oscillator[toneId])
        this.oscillator[toneId].stop(pauseTone(this, toneId));
    },
    stream_based_tone_frequency_download: function(msg) {
      if (this.debug)
        console.log('stream_based_tone_frequency_download...', msg.frequencies )
      this.frequencies[msg.key] = msg.frequencies
    },
    stream_based_tone_cadence_download: function(msg) {
      this.cadences[msg.key] = {
        list: msg.list,
        one_shot: msg.one_shot
      }
    },
    stream_based_tone_on: function(msg) {
      this.initStart()
      this.stream_tone_ids[msg.key] = msg.tone_id
      let cadence = this.cadences[msg.tone_id]
      let freqs = this.frequencies[msg.tone_id]

      for (let id = 0; id < freqs.length; id++) {
        this.startTone(id, freqs[id])
      }
      start_cadence(this, msg.key, msg.tone_id, cadence.one_shot, cadence.list)
    },
    stream_based_tone_off: function(msg) {
      let freqs = this.frequencies[msg.tone_id]

      if (freqs) {
        cancel_cadence(this, msg.key, msg.tone_id)

        for (let id = 0; id < freqs.length; id++) {
          this.stopTone(id)
        }
      }
    }
  };

  window.OneChat.ToneGenerator = ToneGenerator;

  if (InfinityOne.trace_startup) { console.log('finished loading tone generator'); }
})();

function createAudioContext()
{
  return new InfinityOne.AudioContext()
}

function initAudio(tg, toneId) {
  tg.oscillator[toneId] = tg.audioContext.createOscillator();
  fixOscillator(tg.oscillator[toneId]);
  tg.oscillator[toneId].frequency.value = 440;
  tg.amp[toneId] = tg.audioContext.createGain();
  tg.amp[toneId].gain.value = 0;

  // Connect oscillator to amp and amp to the mixer of the audioContext.
  // This is like connecting cables between jacks on a modular synth.
  tg.oscillator[toneId].connect(tg.amp[toneId]);
  tg.amp[toneId].connect(tg.destination);
}

function playTone(tg, toneId, frequency)
{
  var now = tg.audioContext.currentTime;
  tg.oscillator[toneId].frequency.setValueAtTime(frequency, now);

  // Ramp up the gain so we can hear the sound.
  // We can ramp smoothly to the desired value.
  // First we should cancel any previous scheduled events that might interfere.
  tg.amp[toneId].gain.cancelScheduledValues(now);
  // Anchor beginning of ramp at current value.
  tg.amp[toneId].gain.setValueAtTime(tg.amp[toneId].gain.value, now);
  tg.amp[toneId].gain.linearRampToValueAtTime(0.5, tg.audioContext.currentTime + 0.1);
}

function pauseTone(tg, toneId)
{
  var now = tg.audioContext.currentTime;
  var stop_time = tg.audioContext.currentTime + 0.1;

  if (tg.amp[toneId]) {
    tg.amp[toneId].gain.cancelScheduledValues(now);
    tg.amp[toneId].gain.setValueAtTime(tg.amp[toneId].gain.value, now);
    tg.amp[toneId].gain.linearRampToValueAtTime(0.0, stop_time);
  }
  return stop_time;
}

function cadenceSet(tg, streamId, toneId, on) {
  if (on)
    cadenceOn(tg, streamId, toneId)
  else
    cadenceOff(tg, streamId, toneId)
}

function cadenceOn(tg, streamId, toneId) {
  tg.stream_tone_ids[streamId] = toneId
  let freqs = tg.frequencies[toneId]
  for (let id = 0; id < freqs.length; id++) {
    playTone(tg, id, freqs[id])
  }
}

function cadenceOff(tg, streamId, toneId) {
  let freqs = tg.frequencies[toneId]
  if (typeof freqs != "undefined") {
    for (let i = 0; i < freqs.length; i++) {
      pauseTone(tg, i)
    }
  }
}

function start_cadence(tg, stream_id, tone_id, one_shot, list) {
  let cadenceData = {
    stream_id: stream_id,
    tone_id: tone_id,
    one_shot: one_shot,
    list: list,
    on: false,
    index: 0,
    timer_ref: null
  }

  // start the first on cycle and the timer
  init_cadence_timeout(tg, stream_id, tone_id)
  cadence_timeout(tg, cadenceData)
}

function cancel_cadence(tg, stream_id, tone_id) {
  let timer_ref = get_cadence_timeout(tg, stream_id, tone_id)
  if (timer_ref) {
    clearTimeout(timer_ref)
    set_cadence_timeout(tg, stream_id, tone_id, null)
  }
  cadenceOff(tg, stream_id, tone_id)
}

function cadence_timeout(tg, cadenceData) {
  let stop = false
  let timer_ref = null

  if (cadenceData.index >= cadenceData.list.length) {
    cadenceData.index = 0
    if ((cadenceData.list.length % 2) == 1 || cadenceData.one_shot)
      stop = true
  }
  cadenceSet(tg, cadenceData.stream_id, cadenceData.tone_id, !cadenceData.on)

  if (!stop) {
    let timeout = cadenceData.list[cadenceData.index] * 20
    cadenceData.on = !cadenceData.on
    cadenceData.index = cadenceData.index + 1
    timer_ref = setTimeout(cadence_timeout, timeout, tg, cadenceData)
    cadenceData.timer_ref = timer_ref
  }
  set_cadence_timeout(tg, cadenceData.stream_id, cadenceData.tone_id, timer_ref)
}

function init_cadence_timeout(tg, stream_id, tone_id) {
  if (typeof tg.cadence_timeouts[stream_id] === "undefined")
    tg.cadence_timeouts[stream_id] = []
}

function set_cadence_timeout(tg, stream_id, tone_id, timer_ref) {
  tg.cadence_timeouts[stream_id][tone_id] = timer_ref
}

function get_cadence_timeout(tg, stream_id, tone_id) {
  console.log('get_cadence_timeout', tg, stream_id)
  let timer_ref = null
  if (tg.cadence_timeouts[stream_id])
    timer_ref = tg.cadence_timeouts[stream_id][tone_id]
  return timer_ref
}

// Add missing functions to make the oscillator compatible with the later standard.
function fixOscillator(osc)
{
  if (typeof osc.start == 'undefined') {
    osc.start = function(when) {
      osc.noteOn(when);
    }
  }
  if (typeof osc.stop == 'undefined') {
    osc.stop = function(when) {
      osc.noteOff(when);
    }
  }
}

$(document).ready(function() {
  var tg = window.OneChat.ToneGenerator;
  if( tg.audioContext )
  {
    tg.control = document.getElementById('audio-stream')
    tg.initStart()
  } else {
    console.warn('Cannot find audioContext')
  }
});
