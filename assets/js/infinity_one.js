(function() {
  console.log('loading infinity_one');
  var InfinityOne = {
    AudioContext: window.AudioContext || window.webkitAudioContext || window.mozAudioContext,
    hasUserMedia: function() {
      navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;
      return !!navigator.getUserMedia;
    },
    hasRTCPeerConnection: function() {
      window.RTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection || window.mozRTCPeerConnection;
      window.RTCSessionDescription = window.RTCSessionDescription || window.webkitRTCSessionDescription || window.mozRTCSessionDescription;
      window.RTCIceCandidate = window.RTCIceCandidate || window.webkitRTCIceCandidate || window.mozRTCIceCandidate;
      return !!window.RTCPeerConnection;
    },
    Mscs: {},
    trace_startup: true
  }

  window.InfinityOne = InfinityOne;
})();
