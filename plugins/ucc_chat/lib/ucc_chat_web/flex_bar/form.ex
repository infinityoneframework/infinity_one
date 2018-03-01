defmodule UccChatWeb.FlexBar.Form do
  use UccLogger

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false
  import UccChatWeb.RebelChannel.Client
  import UcxUccWeb.Gettext

  alias UccChatWeb.{FlexBar.Helpers, SharedView}
  alias UcxUcc.{TabBar, Accounts}
  alias UccChat.ServiceHelpers


  def flex_form(socket, %{"form" => %{"flex-id" => tab_name}, "dataset" =>
    %{"edit" => control}} = sender) do

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
    socket
  end

  def flex_form_submit(socket, _sender) do
    socket
  end

  def flex_form_save(socket, %{"form" => %{"flex-id" => tab_name} = form} = sender) do
    trace "flex_form_save", sender

    tab = TabBar.get_button tab_name

    {resource, prefix} = get_resource_and_prefix tab, form

    resource_params = ServiceHelpers.normalize_params(form)[prefix]
    model_exported? = function_exported?(resource.__struct__, :model, 0)
    {module, changeset_params, changeset_fun} =
      cond do
        model_exported? and function_exported?(resource.__struct__.model(), :changeset, 3) ->
          user = Accounts.get_user(socket.assigns.user_id, default_preload: true)
          {resource.__struct__.model(), [resource, user, resource_params], :changeset}

        model_exported? and function_exported?(resource.__struct__.model(), :changeset, 2) ->
          {resource.__struct__.model(), [resource, resource_params], :changeset}

        model_exported? and function_exported?(resource.__struct__.model(), :change, 2) ->
          {resource.__struct__.model(), [resource, resource_params], :changeset}

        true ->
          {resource.__struct__, [resource, resource_params], :changeset}
      end

    changeset = apply(module, changeset_fun, changeset_params)

    {changeset_module, action_fun} =
      cond do
        tuple = tab.opts[:changeset] -> tuple
        true -> {module, :update}
      end

    changeset_module
    |> apply(action_fun, [changeset])
    |> case do
      {:ok, resource} ->
        socket
        |> flex_form_cancel(sender)
        |> toastr(:success, gettext("%{prefix} updated successfully",
          prefix: prefix))
        |> notify_update_success(tab, sender,
          %{resource: resource, resource_params: resource_params, changes: changeset.changes})
      {:error, changeset} ->
        _ = changeset
        trace "error", changeset
        errors = SharedView.format_errors changeset
        toastr!(socket, :error, gettext("%{prefix} errors %{errors}",
          prefix: prefix, errors: errors))
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
    update socket, prop: "checked", set: val, on: id

    tab = TabBar.get_button(form["flex-id"])

    {resource, prefix} = get_resource_and_prefix tab, form

    case apply tab.module, :flex_form_toggle, [socket, sender, resource, id, val] do
      {:ok, socket} ->
        socket
        |> toastr(:success, gettext("Successfully updated %{model}", model: prefix))
        |> notify_update_success(tab, sender, %{resource: resource, toggle: id, value: val})
      {:error, changeset, socket} ->
        errors = SharedView.format_errors changeset
        toastr!(socket, :error, gettext("Error updating %{model}: %{errors}",
          model: prefix, errors: errors))
    end
    |> stop_loading_animation()
  end

  def flex_form_delete(socket, sender) do
    form = sender["form"]
    tab = TabBar.get_button(form["flex-id"])
    {resource, prefix} = get_resource_and_prefix(tab, form)

    swal_model socket,
      gettext("Are you sure you want to delete %{name}?", name: prefix),
      ~g(This cannot be cannot be undone), "warning", ~g(Yes, delete it!),
      confirm: fn _ ->
        tab.module
        |> apply(:flex_form_delete, [socket, sender, resource])
        |> case do
          {:ok, socket} ->
            swal socket, ~g(Deleted!),
              gettext("Your %{name} was deleted!", name: prefix),
              "success"
          {:error, changeset} ->
            swal socket, ~g(Sorry!),
              SharedView.format_errors(changeset),
              "error"
        end
      end
    socket
  end

  def flex_form_select_change(socket, sender) do
    trace "flex_form_toggle", sender

    form = sender["form"]

    tab = TabBar.get_button(form["flex-id"])
    field = form_field sender["name"]
    value = sender["value"]

    {resource, _prefix} = get_resource_and_prefix tab, form

    tab.module
    |> apply(:flex_form_select_change, [socket, sender, resource, field, value])
    |> case do
      {:ok, socket} ->
        socket
        |> toastr(:success, gettext("Successfully updated %{model}", model: field))
        |> notify_update_success(tab, sender, %{resource: resource,
          field: field, value: value})
      {:error, _changeset, socket} ->
        toastr(socket, :error, gettext("Error updating %{model}", model: field))
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


