const debug = true

console.log('loading notifier');

OneChat.on_load(function(one_chat) {
  // one_chat.desktop_notifier = new DesktopNotification(one_chat)
  one_chat.notifier = new Notifier(one_chat)
});

class Notifier {
  constructor(one_chat) {
    this.one_chat = one_chat;
    Notification.requestPermission().then(function(result) {
      console.log(result);
    });
  }

  desktop(title, body, opts = {}) {
    var icon = '/images/notification_logo.png';

    if (opts.icon) {
      icon = opts.icon;
    }

    var notification = new Notification(title, {
      body: body,
      icon: icon,
    });

    if (opts.duration) {
      setTimeout(() => {
        notification.close();
      }, opts.duration * 1000);
    }

    notification.opts = opts;

    if (opts.onclick) {
      notification.onclick = opts.onclick;
    }
  }

  audio(sound) {
    if (debug) { console.log('notify_audio', sound) }
    $('audio#' + sound)[0].play()
  }
}

export default Notifier
