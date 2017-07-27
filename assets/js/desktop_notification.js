const debug = true

UccChat.on_load(function(ucc_chat) {
  ucc_chat.desktop_notifier = new DesktopNotification(ucc_chat)
})

class DesktopNotification {
  constructor(ucc_chat) {
    this.ucc_chat = ucc_chat
  }

  notify(name, body, duration) {
    // let icon_path = this.getAvatarAsPng(icon)
    // $('a[data-audio="chime"]').click()
    if (duration) {
      Notification.requestPermission(() => {
        let notify = new Notification(name, {
          body: body,
          icon: '/images/logo_globe.png'
        })
        setTimeout(() => {
          notify.close()
        }, duration * 1000)
      })
    }
  }
  notify_audio(sound) {
    if (debug) { console.log('notify_audio', sound) }
    $('audio#' + sound)[0].play()
  }
  // getAvatarAsPng(icon) {
  //   let image = new Image
  //   image.src = icon
  //   image.onload = () => {
  //     let canvas = document.createElement('canvas')
  //     canvas.width = image.width
  //     canvas.height = image.height
  //     let context = canvas.getContext('2d')
  //     context.drawImage(image, 0, 0)
  //     return canvas.toDataURL('image/png')
  //   }

  // }
}

export default DesktopNotification
