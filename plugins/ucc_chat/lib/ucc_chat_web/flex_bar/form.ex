defmodule UccChatWeb.FlexBar.Form do
  use UccLogger

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import UccChatWeb.RebelChannel.Client
  import UcxUccWeb.Gettext

  alias UccChatWeb.FlexBar.Helpers
  alias UcxUcc.{TabBar, Repo}
  alias UccChat.ServiceHelpers


  def flex_form(socket, %{"form" => %{"id" => tab_name}, "dataset" =>
    %{"edit" => control}} = sender) do

    Logger.warn "flex_form edit tab_name: #{tab_name}, control: #{control} sender: #{inspect sender}"
    tab = TabBar.get_button(tab_name)
    user_id = socket.assigns.user_id
    channel_id = Helpers.get_channel_id socket
    apply tab.module, :open, [socket, user_id, channel_id, tab, %{"editing" => control}]
  end

  def flex_form(socket, sender) do
    trace "flex_form sender", sender
    socket
  end

  def flex_form_save(socket, %{"form" => %{"id" => tab_name} = form} = sender) do
    trace "flex_form_save", sender

    tab = TabBar.get_button tab_name

    {_assigns, resource_key, resource} = get_assigns_and_resource socket

    resource_params = ServiceHelpers.normalize_params(form)[to_string(resource_key)]

    resource.__struct__
    |> apply(:changeset, [resource, resource_params])
    |> log_inspect(:warn, label: "changeset")
    |> Repo.update()
    |> log_inspect(:warn, label: "after update")
    |> case do
      {:ok, resource} ->
        socket
        |> Phoenix.Socket.assign(resource_key, resource)
        |> flex_form_cancel(sender)
        |> toastr!(:success, "#{resource_key} updated successfully")
        |> notify_update_success(tab, sender,
          %{resource: resource, resource_params: resource_params})
      {:error, changeset} ->
        trace "error", changeset
        toastr!(socket, :error, "Problem updating #{resource_key}")
    end
  end

  def flex_form_cancel(socket, %{"form" => %{"id" => tab_name}} = sender) do
    trace "flex_form_cancel", sender
    tab = TabBar.get_button(tab_name)
    user_id = socket.assigns.user_id
    channel_id = Helpers.get_channel_id socket
    apply tab.module, :open, [socket, user_id, channel_id, tab, %{}]
  end

  def flex_form_toggle(socket, sender) do
    trace "flex_form_toggle", sender

    id = "#" <> sender["dataset"]["id"]

    start_loading_animation(socket, id)

    val = !select(socket, prop: "checked", from: id)
    update socket, prop: "checked", set: val, on: id

    tab = TabBar.get_button(sender["form"]["id"])

    {_assigns, _resource_key, resource} = get_assigns_and_resource socket

    case apply tab.module, :flex_form_toggle, [socket, sender, resource, id, val] do
      {:ok, socket} ->
        socket
        |> toastr!(:success, gettext("Successfully updated %{model}",
          model: sender["form"]["id"]))
        |> notify_update_success(tab, sender, %{resource: resource, toggle: id, value: val})
      {:error, _changeset, socket} ->
        toastr!(socket, :error, gettext("Error updating %{model}",
          model: sender["form"]["id"]))
    end
    |> stop_loading_animation()
  end

  def flex_form_select_change(socket, sender) do
    trace "flex_form_toggle", sender

    tab = TabBar.get_button(sender["form"]["id"])
    field = form_field sender["name"]
    value = sender["value"]

    {_assigns, _resource_key, resource} = get_assigns_and_resource(socket)

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

  defp get_assigns_and_resource(socket) do
    assigns = Rebel.get_assigns socket
    resource_key = assigns[:resource_key]
    {assigns, resource_key, assigns[resource_key]}
  end

  defp notify_update_success(socket, tab, sender, opts) do
    apply tab.module, :notify_update_success, [socket, tab, sender, opts]
  end
end


