defmodule OneWikiWeb.FlexBar.Tab.Info do
  @moduledoc """
  OneWiki Info Flex Tab.
  """
  use OneChatWeb.FlexBar.Helpers
  use OneLogger

  alias InfinityOne.{TabBar.Tab}
  alias InfinityOne.{TabBar}
  alias OneWikiWeb.FlexBarView
  alias OneChatWeb.RebelChannel.Client
  alias OneChat.ServiceHelpers
  alias OneWiki.Page

  @doc """
  Show Info about the page.
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[wiki],
      "wiki_info",
      ~g"Info",
      "icon-info-circled",
      FlexBarView,
      "info.html",
      10,
      [
        model: Page,
        prefix: "page"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the Backup panel.
  """
  def args(socket, {user_id, _channel_id, _, _,}, _params) do
    current_user = Helpers.get_user! user_id
    opts = get_opts()
    page = socket.assigns.page

    log =
      case OneWiki.Git.log(page.id) do
        {:error, error} -> error
        results -> results
      end
      |> IO.inspect(label: "git info")

    {[
      current_user: current_user,
      changeset: Page.change(page),
      opts: opts,
      page: page,
      log: log
    ], socket}
  end

  @doc """
  Perform a backup
  """
  def flex_form_save(socket, %{"form" => form} = sender) do
    resource_params = ServiceHelpers.normalize_params(form)["backup"] || %{}

    # params =
    #   for {key, val} <- resource_params, into: %{} do
    #     {String.to_existing_atom(key), val == "1"}
    #   end

    # Client.prepend_loading_animation(socket, ".content.backup", :light_on_dark)

    # case create_backup(params, Enum.any?(params, &elem(&1, 1))) do
    #   {:ok, name} ->
    #     socket
    #     |> Client.stop_loading_animation()
    #     |> Channel.flex_close(sender)
    #     |> async_js(~s/$('a.admin-link[data-id="admin_backup_restore"]').click()/)
    #     |> Client.toastr(:success, gettext("Backup %{name} created successfully!", name: name))

    #   {:error, message} when is_binary(message) ->
    #     socket
    #     |> Client.stop_loading_animation()
    #     |> Client.toastr(:error, message)

    #   {:error, message} ->
    #     socket
    #     |> Client.stop_loading_animation()
    #     |> Client.toastr(:error, inspect(message))

    #   false ->
    #     socket
    #     |> Client.stop_loading_animation()
    #     |> Client.toastr(:error, ~g(Must select at least one backup option!))
    # end
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, sender) do
    # Channel.flex_close(socket, sender)
    socket
  end

  # defp create_backup(_params, false), do: false


  def get_opts do
    %{
    }
  end

end
