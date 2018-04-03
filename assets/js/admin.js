import toastr from 'toastr'
import * as flex from './flex_bar'

console.log('loading admin');

const reset_i = '<i class="icon-ccw secondary-font-color color-error-contrast"></i>'

OneChat.on_load(function(one_chat) {
  one_chat.admin = new Admin(one_chat)
})

class Admin {
  constructor(one_chat) {
    this.one_chat = one_chat
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
  add_reset_setting_button(target, input_line) {
    let data_settings = target.getAttribute('name').replace('[', '__').replace(']', '')
    let reset = `<button text='Reset' data-setting="${data_settings}"
      class="reset-settings button danger" rebel-click="admin_reset_setting_click">${reset_i}</button>`
    if (input_line.find('button.reset-settings').length === 0) {
      input_line.append(reset);

      Rebel.set_event_handlers($(target).selector);
    }
  }
  handle_change(e) {
    let target = e.currentTarget;
    let input_line = $(target).closest('.input-line');
    this.enable_save_button()
    input_line.addClass('setting-changed')
    this.add_reset_setting_button(target, input_line);
  }
  register_events(admin) {
    $('body')
      .on('click', 'button.discard', () => {
        // admin.disable_save_button()
        $('a.admin-link[data-id="admin_info"]').click()
      })
      .on('change', '.admin-settings form input:not(.search)', (e) => {
        this.handle_change(e);
      })
      .on('change', '.admin-settings form select', (e) => {
        this.handle_change(e);
      })
      .on('keyup keypress paste', '.admin-settings form input:not(.search)', (e) => {
        this.handle_change(e);
      })
      .on('keyup keypress paste', '.admin-settings form textarea', (e) => {
        this.handle_change(e);
      })
      .on('change', '.permissions-manager [type="checkbox"]', function(e, t) {
        e.preventDefault()
        console.log('checkbox change t', $(this))
        let name = $(this).attr('name')
        let value = $(this).is(':checked')

        if (!value) { value = "false" }
        OneChat.userchan.push('admin:permissions:change:' + name, {value: value})
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
        OneChat.userchan.push('admin:save:' + $('form').data('id'), $('form').serializeArray())
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
        let new_password = OneChat.randomString(12)
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
        OneChat.userchan.push('admin:save:user', $('form.user').serializeArray())
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
        OneChat.userchan.push('admin:permissions:role:new', {})
      })
      .on('click', 'a[href="#admin-permissions-edit"]', e => {
        let name = $(e.currentTarget).attr('name')
        console.log('permissions edit', name)
        OneChat.userchan.push('admin:permissions:role:edit', {name: name})
      })
      .on('click', '.admin-role.delete', e => {
        let name = $(e.currentTarget).attr('data-name')
        OneChat.userchan.push('admin:permissions:role:delete', {name: name})
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
      .on('click', 'form.backup .input.toggle', e => {
        var input = $(e.currentTarget).find('input');
        if (input.prop('checked')) {
          input.prop('checked', false);
        } else {
          input.prop('checked', true);
        }
      })
      .on('change', '#backups-change-all', e => {
        var checked = $(e.currentTarget).prop('checked');
        var list = $('section.page-container input.check');
        for (var i = 0; i < list.length; i++) {
          $(list[i]).prop('checked', checked);
        }
        this.enable_disable_batch_delete();
      })
      .on('change', 'section.page-container input.check', e => {
        this.enable_disable_batch_delete();
      })
  }

  enable_disable_batch_delete() {
    if ($('section.page-container input.check:checked').length > 0) {
       $('#batch-delete').removeAttr('disabled')
    } else {
       $('#batch-delete').attr('disabled', true)
    }
  }

  close_edit_form(name) {
    OneChat.userchan.push('admin:flex:user-info', {name: name})
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
    OneChat.userchan.push('admin:channel-settings:' + action, params)
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
