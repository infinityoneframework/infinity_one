defmodule OneWikiWeb.WikiChannel do
  use OneLogger
  use InfinityOne
  use OneWikiWeb, :channel

  use Rebel.Channel, name: "wiki", controllers: [
    OneChatWeb.ChannelController,
  ], intercepts: [
  ]

  alias OneChat.ServiceHelpers, as: Helpers
  alias OneWikiWeb.PageView
  alias OneWiki.Page
  alias InfinityOne.Accounts
  alias OneChatWeb.RebelChannel.Client
  alias OneChatWeb.SharedView
  # alias InfinityOne.{OneubSub, Accounts}

  require OneChat.ChatConstants, as: CC

  def topic(_broadcasting, _controller, _request_path, conn_assigns) do
    topic = conn_assigns[:current_user] |> Map.get(:id)
    Logger.debug "WikiChannel topic call: #{topic}"
    topic
  end

  def join(CC.chan_wiki() <> user_id = ev, payload, socket) do
    send(self(), :after_join)

    # :ok = OneChat.ChannelMonitor.monitor(:chan_system, self(),
    #   {__MODULE__, :leave, [socket.assigns.user_id]})
    super(ev, payload, socket)
  end

  # def leave(pid, user_id) do
  #   # user = Accounts.get_user user_id
  #   # if user.status in [nil, ""] do
  #   #   OneChat.PresenceAgent.unload(user_id)
  #   # end
  #   # InfinityOneWeb.Presence.untrack(pid, CC.chan_system(), user_id)
  #   # OnePubSub.broadcast("user:" <> user_id, "user:leave")
  # end

  def handle_info(:after_join, socket) do
    Logger.warn "Wiki after join"
    {:noreply, socket}
  end


  ###############
  # handle_in


  def new_page(socket, sender) do
    Logger.warn "sender: " <> inspect(sender)
    Logger.warn "assigns: " <> inspect(socket.assigns)
    html = Phoenix.View.render_to_string(PageView, "new.html", [])
    Rebel.Query.update(socket, :html, set: html, on: ".main-content")
  end

  def open_page(socket, sender) do
    Logger.warn "sender: " <> inspect(sender)
    Logger.warn "assigns: " <> inspect(socket.assigns)
    name = sender["dataset"]["name"]
    render_page(Page.get_by(title: name), socket)
  end

  defp render_page(page, socket) do
    body =
      case Earmark.as_html(page.body) do
        {:ok, body, _} -> body
        {:error, error} -> inspect(error)
      end
    html = Phoenix.View.render_to_string(PageView, "show.html", title: page.title, body: body, id: page.id)
    Rebel.Query.update(socket, :html, set: html, on: ".main-content")
  end

  def create_page(socket, %{"form" => form} = sender) do
    Logger.warn "sender: " <> inspect(sender)
    Logger.warn "assigns: " <> inspect(socket.assigns)
    user = Accounts.get_user socket.assigns.user_id, default_preload: true

    resource_params = (Helpers.normalize_params(form)["wiki"])
    |> IO.inspect(label: "resource_params")

    case Page.create(user, resource_params) do
      {:ok, _page} ->
        Client.toastr(socket, :success, ~g(Page created successfully!))
      {:error, changeset} ->
        errors = SharedView.format_errors(changeset)
        Client.toastr(socket, :error, gettext("Problem creating page: %{errors}", errors: errors))
    end
  end

  def edit_page(socket, sender) do
    Logger.warn "sender: " <> inspect(sender)
    Logger.warn "assigns: " <> inspect(socket.assigns)
    # user = Accounts.get_user socket.assigns.user_id, default_preload: true

    page = Page.get(sender["dataset"]["id"])

    html = Phoenix.View.render_to_string(PageView, "edit.html", title: page.title, body: page.body, id: page.id)
    Rebel.Query.update(socket, :html, set: html, on: ".main-content")
  end

  def update_page(socket, %{"form" => form} = sender) do
    Logger.warn "sender: " <> inspect(sender)
    Logger.warn "assigns: " <> inspect(socket.assigns)

    resource_params = (Helpers.normalize_params(form)["wiki"])
    page = Page.get(form["id"])
    case Page.update(page, resource_params) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page updated successfully.))
        render_page(page, socket)
      {:error, changeset} ->
        errors = SharedView.format_errors(changeset)
        Client.toastr(socket, :error, gettext("Problem updating page: %{errors}", errors: errors))

    end
  end

  def cancel_edit(socket, sender) do
    Logger.warn "sender: " <> inspect(sender)
    Logger.warn "assigns: " <> inspect(socket.assigns)
    socket
  end
end
