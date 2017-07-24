defmodule UccChat.Web.FlexBar.Form do
  use UccLogger

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false

  alias UccChat.Web.FlexBar.Helpers
  alias UcxUcc.TabBar
  alias UccChat.ServiceHelpers
  alias UcxUcc.Repo

  def flex_form(socket, %{"form" => %{"id" => tab_name}, "dataset" =>
    %{"edit" => control}} = sender) do

    Logger.warn "flex_form edit tab_name: #{tab_name}, control: #{control} sender: #{inspect sender}"
    tab = TabBar.get_button(tab_name)
    apply tab.module, :open, [socket, nil, tab, nil, %{"editing" => control}]
  end

  def flex_form(socket, sender) do
    trace "flex_form sender", sender
    socket
  end

  def flex_form_save(socket, %{"form" => %{"id" => _tab_name} = form} = sender) do
    trace "flex_form_save", sender

    assigns = socket.assigns

    resource_key = assigns[:resource_key]
    resource_params = ServiceHelpers.normalize_params(form)[to_string(resource_key)]
    resource = assigns[resource_key]

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
        |> Helpers.toastr(:success, "#{resource_key} updated successfully")
      {:error, changeset} ->
        trace "error", changeset
        Helpers.toastr(socket, :error, "Problem updating #{resource_key}")
        socket
    end
  end

  def flex_form_cancel(socket, %{"form" => %{"id" => tab_name}} = sender) do
    trace "flex_form_cancel", sender
    tab = TabBar.get_button(tab_name)
    apply tab.module, :open, [socket, nil, tab, nil, %{}]
  end
end

