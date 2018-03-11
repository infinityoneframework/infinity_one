(function() {
  console.log('loading avatar');

  OneChat.on_load(function(one_chat) {
    Avatar.load();
    OneChat.avatar = Avatar;
  });

  const prefix = '.input-line.set-avatar ';
  const avatar = '.avatar-full';
  const small_avatar = '.avatar-initials';
  const avatar_url_ctrl = '#user_avatar_url';
  const delete_ctrl = '#user_delete_avatar';

  var Avatar = {
    load: function() {
      this.which = false;
      $('body')
        // Handle clicking the small avatar image.
        .on('click', prefix + small_avatar, function(e) {
          let existing = get_img_src(avatar);
          let other = get_img_src(small_avatar);

          set_img_src(avatar, other);
          set_img_src(small_avatar, existing);

          if (!this.which) {
            $(avatar_url_ctrl).val(other);
            $(delete_ctrl).val(true);
          } else {
            $(avatar_url_ctrl).val('');
            $(delete_ctrl).val(false);
          }
          this.which = !this.which;
        })
    },
    uploadedUrl: function(url) {
      set_img_src(avatar, url);
      this.which = false;
      $(avatar_url_ctrl).val('');
    }
  };

  function get_img_src(which) {
    return $(prefix + which + ' img').attr('src');
  }

  function set_img_src(which, value) {
    return $(prefix + which + ' img').attr('src', value);
  }

})();
