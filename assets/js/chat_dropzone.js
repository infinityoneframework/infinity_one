console.log('loading chat_dropzone');

$(document).ready(() => {
  window.isAdvancedUpload = function() {
    var div = document.createElement('div');
    return (('draggable' in div) || ('ondragstart' in div && 'ondrop' in div)) && 'FormData' in window && 'FileReader' in window;
  }();
  if (isAdvancedUpload) {
    let droppedFiles = false;
    let enterTarget = null;
    let obj = $('.dropzone');

    $('body').on('drag dragstart dragend dragover dragenter dragleave drop', '.dropzone', e => {
      e.preventDefault();
      e.stopPropagation();
    })
    .on('dragover dragenter', '.dropzone', (e) => {
      if (chat_settings.allow_upload) {
        enterTarget = e.target;
        $('.dropzone').addClass('over');
      }
    })
    .on('dragleave dragend drop', '.dropzone', (e) => {
      if (enterTarget == e.target) {
        $('.dropzone').removeClass('over');
      }
    })
    .on('drop', '.avatar-dropzone', event => {
      // handle the avatar image file drop
      if (chat_settings.allow_upload) {
        let e = event.originalEvent || event;
        let files = e.dataTransfer.files || [];
        OneChat.fileUpload.handleAvatarUpload(files, obj);
      }
    })
    .on('drop', '.site-avatar-dropzone', event => {
      if (chat_settings.allow_upload) {
        let e = event.originalEvent || event;
        let files = e.dataTransfer.files || [];
        OneChat.fileUpload.handleSiteAvatarUpload(files, obj);
      }
    })
    .on('drop', '.attachment-dropzone', event => {
      // handle the attachment file drop
      if (chat_settings.allow_upload) {
        let e = event.originalEvent || event;
        let files = e.dataTransfer.files || [];
        OneChat.fileUpload.handleFileUpload(files, obj);
      }
    });
  }
});
