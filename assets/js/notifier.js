const debug = true

console.log('loading notifier');

OneChat.on_load(function(one_chat) {
  // one_chat.desktop_notifier = new DesktopNotification(one_chat)
  one_chat.notifier = new Notifier(one_chat)
});

class Notifier {
  constructor(one_chat) {
    this.one_chat = one_chat;
    let promise = Notification.requestPermission();
    if (promise) {
      promise.then(function(result) {
        console.log('request permissions', result);
      });
    } else {
      console.log('no promise returned');
    }
    this.useNewNotification = this.supportsNewNofification();
  }

  desktop(title, body, opts = {}) {
    var icon = '/images/notification_logo.png';

    if (opts.icon) {
      icon = opts.icon;
    }

    var notification = this.newNotification(title, {
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

  newNotification(title, opts = {}) {
    let not;
    if (this.useNewNotification) {
      not = new Notification(title, opts);
    } else {
      not = Notification(title, opts);
    }
    return not;
  }

  audio(sound) {
    if (debug) { console.log('notify_audio', sound) }
    $('audio#' + sound)[0].play()
  }

  supportsNewNofification() {
    if (!window.Notification || !Notification.requestPermission)
      return false;

    try {
      new Notification('');
    } catch (e) {
      if (e.name == 'TypeError')
        return false;
    }
    return true;
  }
}

export default Notifier
