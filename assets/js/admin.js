import toastr from 'toastr'
import * as flex from './flex_bar'

console.log('loading admin');

const reset_i = '<i class="icon-ccw secondary-font-color color-error-contrast"></i>'

UccChat.on_load(function(ucc_chat) {
  ucc_chat.admin = new Admin(ucc_chat)
})

class Admin {
  constructor(ucc_chat) {
    this.ucc_chat = ucc_chat
    this.modifed = false
    this.register_events(this)
  }

  enable_save_button() {
    let save = $('button.save')
    if (save.attr('disabled') == 'disabled') {
      save.removeAttr('disabled')
      save.parent().prepend(`<button class="button danger discard"><i class="icon-send"></i><span>${gettext.cancel}</span></button>`)
      this.modified = true
    }
  }
  disable_save_button() {
    let save = $('button.save')
    this.modified = false
    save.attr('disabled', 'disabled')
    $('button.discard').remove()
  }
  register_events(admin) {
    $('body')
      .on('click', 'button.discard', function() {
        // admin.disable_save_button()
        $('a.admin-link[data-id="admin_info"]').click()
      })
      .on('change', '.admin-settings form input:not(.search)', function(e) {
        let target = e.currentTarget
        admin.enable_save_button()
        let reset = `<button text='Reset' data-setting="${target.getAttribute('name')}" class="reset-setting button danger">${reset_i}</button>`
        $(this).closest('.input-line').addClass('setting-changed') //.append(reset)
      })
      .on('change', '.admin-settings form select', function(e) {
        admin.enable_save_button()
        $(this).closest('.input-line').addClass('setting-changed') //.append(reset)
      })
      .on('keyup keypress paste', '.admin-settings form input:not(.search)', function(e) {
        admin.enable_save_button()
        $(this).closest('.input-line').addClass('setting-changed') //.append(reset)
      })
      .on('keyup keypress paste', '.admin-settings form textarea', function(e) {
        admin.enable_save_button()
        $(this).closest('.input-line').addClass('setting-changed') //.append(reset)
      })
      .on('change', '.permissions-manager [type="checkbox"]', function(e, t) {
        e.preventDefault()
        console.log('checkbox change t', $(this))
        let name = $(this).attr('name')
        let value = $(this).is(':checked')

        if (!value) { value = "false" }
        UccChat.userchan.push('admin:permissions:change:' + name, {value: value})
        .receive("ok", resp => {
          // stop_loading_animation()
          toastr.success('Room ' + name + ' updated successfully.')
        })
      })
      .on('click', '.page-settings .section button.expand', function(e) {
        e.preventDefault()
        $(this)
          .addClass('collapse')
          .removeClass('expand')
          .first().html('Collapse')
          .closest('.section-collapsed')
          .removeClass('section-collapsed')
      })
      .on('click', '.page-settings .section button.collapse', function(e) {
        e.preventDefault()
        $(this)
          .removeClass('collapse')
          .addClass('expand')
          .first().html('Expand')
          .closest('.section-title')
          .parent()
          .addClass('section-collapsed')
      })
      .on('click', '.admin-settings button.save', function(e) {
        //console.log('saving form....', $('form').data('id'))
        e.preventDefault()
        UccChat.userchan.push('admin:save:' + $('form').data('id'), $('form').serializeArray())
          .receive("ok", resp => {
            if (resp.success) {
              admin.disable_save_button()
              toastr.success(resp.success)
            } else if (resp.error) {
              toastr.error(resp.error)
            }
        })
      })
      .on('click', 'button.refresh', function(e) {
        let page = $(this).closest('section').data('page')
        $('a.admin-link[data-id="' + page + '"]').click()
      })
      .on('click', 'section.admin .list-view.channel-settings span[data-edit]', (e) => {
        let channel_id = $(e.currentTarget).closest('[data-id]').data('id')
        this.userchan_push('edit', {channel_id: channel_id, field: $(e.currentTarget).data('edit')})
      })
      .on('click', 'section.admin .channel-settings button.save', e => {
        let channel_id = $(e.currentTarget).closest('[data-id]').data('id')
        let params = $('.channel-settings form').serializeArray()
        this.userchan_push('save', {channel_id: channel_id, params: params})
      })
      .on('click', 'section.admin .channel-settings button.cancel', e => {
        let channel_id = $(e.currentTarget).closest('[data-id]').data('id')
        this.userchan_push('cancel', {channel_id: channel_id})
      })
      .on('click', '#showPassword', e => {
        let prefix = "";
        if ($('#user_password').length > 0) {
          prefix = "user_";
        }
        let password_name = `#${prefix}password`
        let password_confirmation_name = `#${prefix}password_confirmation`
        $(e.currentTarget).hide();
        $('#hidePassword').show();
        $(password_name).attr('type','text');
        $(password_confirmation_name).attr('type','text');
      })
      .on('click', '#hidePassword', e => {
        let prefix = "";
        if ($('#user_password').length > 0) {
          prefix = "user_";
        }
        let password_name = `#${prefix}password`
        let password_confirmation_name = `#${prefix}password_confirmation`
        $(e.currentTarget).hide();
        $('#showPassword').show();
        $(password_name).attr('type','password');
        $(password_confirmation_name).attr('type','password');
      })
      .on('click', '#randomPassword', e => {
        let new_password = UccChat.randomString(12)
        let prefix = "";
        if ($('#user_password').length > 0) {
          prefix = "user_";
        }
        let password_name = `#${prefix}password`
        let password_confirmation_name = `#${prefix}password_confirmation`

        e.preventDefault()
        e.stopPropagation()
        $(password_name).attr('type', 'password').val(new_password)
        $(password_confirmation_name).attr('type', 'password').val(new_password)
        $('#showPassword').show();
        $('#hidePassword').hide();
      })
      .on('click', 'section.admin form.user button.save', e => {
        UccChat.userchan.push('admin:save:user', $('form.user').serializeArray())
          .receive("ok", resp => {
            if (resp.success) {
              toastr.success(resp.success)
              this.close_edit_form($('form.user').data('username'))
            } else if (resp.error) {
              toastr.error(resp.error)
            }
          })
          .receive("error", resp => {
            console.log('error resp', resp)
            if (resp.error) {
              toastr.error(resp.error)
            }
            if (resp.errors) {
              this.show_form_errors(resp.errors)
            }
          })
      })
      .on('click', 'section.admin form.user button.cancel', e => {
        this.close_edit_form($('form.user').data('username'))
      })
      .on('click', 'a.new-role', e => {
        UccChat.userchan.push('admin:permissions:role:new', {})
      })
      .on('click', 'a[href="#admin-permissions-edit"]', e => {
        let name = $(e.currentTarget).attr('name')
        console.log('permissions edit', name)
        UccChat.userchan.push('admin:permissions:role:edit', {name: name})
      })
      .on('click', '.admin-role.delete', e => {
        let name = $(e.currentTarget).attr('data-name')
        UccChat.userchan.push('admin:permissions:role:delete', {name: name})
      })
      .on('click', 'a[href="/admin/permissions"]', e => {
        e.preventDefault();
        e.stopPropagation();

        $('.admin-link[data-id="admin_permissions"]').click();
        return false;
      })
      .on('mouseenter', '.-autocomplete-item', e => {
        $('.-autocomplete-item').removeClass('selected');
        $(e.currentTarget).addClass('selected');
      })
      .on('keydown', '#search-room', e => {
        return this.handle_search_keys(e, 'rooms');
      })
      .on('keydown', '#user-roles-search', e => {
        return this.handle_search_keys(e, 'users');
      })
  }

  close_edit_form(name) {
    UccChat.userchan.push('admin:flex:user-info', {name: name})
      .receive("ok", resp => {
        $('section.flex-tab').html(resp.html).parent().addClass('opened')
        flex.set_tab_buttons_inactive()
        flex.set_tab_button_active(resp.title)
        // console.log('admin flex receive', resp)
      })

  }

  show_form_errors(errors) {
    console.log('error keys', Object.keys(errors))
    $('.has-error').removeClass('has-error')
    $('.help-block').remove()
    for (var error in errors) {
      console.log('error', error, errors[error])
      let span = `<span class="help-block">${errors[error]}</span>`
      $('#' + error).parent().addClass('has-error').append(span)
    }
  }
  userchan_push(action, params) {
    UccChat.userchan.push('admin:channel-settings:' + action, params)
      .receive("ok", resp => {
        if (resp.html) {
          $('.content.channel-settings').replaceWith(resp.html)
        }
      })
      .receive("error", resp => {
        this.do_toastr(resp)
      })
  }
  do_toastr(resp) {
    if (resp.success) {
      toastr.success(resp.success)
    } else if (resp.error) {
      toastr.error(resp.error)
    } else if (resp.warning) {
      toastr.warning(resp.warning)
    }
  }

  handle_search_keys(e, which) {
    if (e.key == 'ArrowDown' || e.key == 'ArrowUp') {
      e.preventDefault();
      e.stopPropagation();

      let container = '.users';
      if (which == 'rooms') {
        container = '.rooms';
      }

      let current = $(`.-autocomplete-container${container} .-autocomplete-item.selected`);
      let siblings = $(`.-autocomplete-container${container} .-autocomplete-item`);

      let select = function(item) {
        item.addClass('selected');
      };

      current.removeClass('selected');

      if (e.key == "ArrowDown") {
        let next = current.next();
        if (next.length > 0) {
          next.addClass('selected');
        } else {
          let first = siblings.first();
          first.addClass('selected');
        }
      } else {
        let prev = current.prev();
        if (prev.length > 0) {
          prev.addClass('selected');
        } else {
          let last = siblings.last();
          last.addClass('selected')
        }
      }
      return false;
    }
  }
}

export default Admin
