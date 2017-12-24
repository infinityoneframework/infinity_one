defmodule UccChatWeb.FlexBar.Form do
  use UccLogger

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import UccChatWeb.RebelChannel.Client
  import UcxUccWeb.Gettext

  alias UccChatWeb.FlexBar.Helpers
  alias UcxUcc.{TabBar, Repo}
  alias UccChat.ServiceHelpers


  def flex_form(socket, %{"form" => %{"flex-id" => tab_name}, "dataset" =>
    %{"edit" => control}} = sender) do

    # Logger.debug "flex_form edit tab_name: #{tab_name}, control: #{control} sender: #{inspect sender}"
    tab = TabBar.get_button(tab_name)
    user_id = socket.assigns.user_id
    channel_id = Helpers.get_channel_id socket
    apply tab.module, :open, [socket, {user_id, channel_id, tab, sender}, %{"editing" => control}]
  end

  def flex_form(socket, sender) do
    trace "flex_form sender", sender
    socket
  end

  # TODO: this it not implemented and should be removed later if we don't
  #       need it
  def flex_form_change(socket, _sender) do
    # Logger.debug "sender: " <> inspect(sender)
    socket
  end

  def flex_form_submit(socket, _sender) do
    socket
  end
  # def flex_form_save(socket, %{"event" => %{"type" => "click"}} = sender) do
  #   # ignore this message since it will be handled by the change event
  #   socket
  # end
  def flex_form_save(socket, %{"form" => %{"flex-id" => tab_name} = form} = sender) do
    trace "flex_form_save", sender
    # Logger.error "sender: " <> inspect(sender)

    tab = TabBar.get_button tab_name

    # IO.inspect tab.opts[:model], label: "model"
    # IO.inspect form, label: "form"

    {resource, prefix} = get_resource_and_prefix tab, form

    resource_params = ServiceHelpers.normalize_params(form)[prefix]

    resource.__struct__
    |> apply(:changeset, [resource, resource_params])
    |> log_inspect(:debug, label: "changeset")
    |> Repo.update()
    |> log_inspect(:debug, label: "after update")
    |> case do
      {:ok, resource} ->
        socket
        |> flex_form_cancel(sender)
        |> toastr!(:success, gettext("%{prefix} updated successfully",
          prefix: prefix))
        |> notify_update_success(tab, sender,
          %{resource: resource, resource_params: resource_params})
      {:error, changeset} ->
        _ = changeset
        trace "error", changeset
        toastr!(socket, :error, gettext("Problem updating %{prefix}",
          prefix: prefix))
    end
  end

  def flex_form_cancel(socket, %{"form" => %{"flex-id" => tab_name}} = sender) do
    trace "flex_form_cancel", sender
    _ = sender
    tab = TabBar.get_button(tab_name)
    user_id = socket.assigns.user_id
    channel_id = Helpers.get_channel_id socket

    if ret_socket = notify_cancel(socket, tab, sender) do
      ret_socket
    else
      apply tab.module, :open, [socket, {user_id, channel_id, tab, sender}, %{}]
    end
  end

  def flex_form_toggle(socket, sender) do
    trace "flex_form_toggle", sender

    form = sender["form"]
    id = "#" <> sender["dataset"]["id"]

    start_loading_animation(socket, id)

    val = !select(socket, prop: "checked", from: id)
    Logger.debug "id: " <> inspect(id) <> ", val: " <> inspect(val)
    update socket, prop: "checked", set: val, on: id

    tab = TabBar.get_button(form["flex-id"])

    # {_assigns, _resource_key, resource} = get_assigns_and_resource socket
    {resource, prefix} = get_resource_and_prefix tab, form

    case apply tab.module, :flex_form_toggle, [socket, sender, resource, id, val] do
      {:ok, socket} ->
        socket
        |> toastr!(:success, gettext("Successfully updated %{model}",
          model: prefix))
          # model: sender["form"]["flex-id"]))
        |> notify_update_success(tab, sender, %{resource: resource, toggle: id, value: val})
      {:error, _changeset, socket} ->
        toastr!(socket, :error, gettext("Error updating %{model}",
          model: prefix))
    end
    |> stop_loading_animation()
  end

  def flex_form_select_change(socket, sender) do
    trace "flex_form_toggle", sender
    # Logger.warn "..... #{inspect sender}"
    form = sender["form"]

    tab = TabBar.get_button(form["flex-id"])
    field = form_field sender["name"]
    value = sender["value"]
    # Logger.warn inspect({form["flex-id"], field, value, tab})

    # {_assigns, _resource_key, resource} = get_assigns_and_resource(socket)
    {resource, _prefix} = get_resource_and_prefix tab, form

    tab.module
    |> apply(:flex_form_select_change, [socket, sender, resource, field, value])
    |> case do
      {:ok, socket} ->
        socket
        |> toastr!(:success, gettext("Successfully updated %{model}",
          model: field))
        |> notify_update_success(tab, sender, %{resource: resource,
          field: field, value: value})
      {:error, _changeset, socket} ->
        toastr!(socket, :error, gettext("Error updating %{model}",
          model: field))
    end
  end

  defp form_field(name) do
    [_, field] = Regex.run ~r/.*\[(.+)\]/, name
    field
  end

  # defp get_assigns_and_resource(socket) do
  #   assigns = Rebel.get_assigns socket
  #   resource_key = assigns[:resource_key]
  #   {assigns, resource_key, assigns[resource_key]}
  # end

  defp get_resource_and_prefix(tab, form) do
    prefix = tab.opts[:prefix]
    id = form["#{prefix}[id]"]
    # Logger.warn "prefix: " <> inspect(prefix) <> ", id: " <> inspect(id) <> ", form: " <> inspect(form)

    model =
      case tab.opts[:get] do
        nil              -> apply(tab.opts[:model], :get, [id])
        {mod, fun}       -> apply(mod, fun, [id])
        {mod, fun, opts} -> apply(mod, fun, [id] ++ opts)
      end

    {model, prefix}
  end

  defp notify_update_success(socket, tab, sender, opts) do
    apply tab.module, :notify_update_success, [socket, tab, sender, opts]
  end

  defp notify_cancel(socket, tab, sender) do
    if function_exported? tab.module, :notify_cancel, 3 do
      apply tab.module, :notify_cancel, [socket, tab, sender]
    end
  end
end


