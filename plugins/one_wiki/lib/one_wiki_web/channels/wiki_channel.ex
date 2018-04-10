defmodule OneWikiWeb.WikiChannel do
  use OneLogger
  use InfinityOne
  use OneWikiWeb, :channel

  use Rebel.Channel, name: "wiki", controllers: [
    OneChatWeb.ChannelController,
  ], intercepts: [
  ]

  alias OneChat.ServiceHelpers, as: Helpers
  alias OneWikiWeb.{PageView, SidenavView}
  alias OneWiki.Page
  alias InfinityOne.Accounts
  alias OneChatWeb.RebelChannel.Client
  alias OneChatWeb.{SharedView, MessageView}
  alias OneChatWeb.RebelChannel.{SideNav}
  alias InfinityOneWeb.Query

  require OneChat.ChatConstants, as: CC

  def topic(_broadcasting, _controller, _request_path, conn_assigns) do
    conn_assigns[:current_user] |> Map.get(:id)
  end

  def join(CC.chan_wiki() <> _user_id = ev, payload, socket) do
    send(self(), :after_join)
    super(ev, payload, socket)
  end

  def handle_info(:after_join, socket) do
    Logger.warn "Wiki after join"
    {:noreply, socket}
  end

  ###############
  # handle_in

  def handle_in("open_room", %{"title" => title} = payload, socket) do
    Logger.warn "payload: " <> inspect(payload)
    if payload["new_page"] do
      {:noreply, new_page(socket, %{}, title)}
    else
      {:noreply, open(socket, URI.decode(title))}
    end
  end

  defp sidenav(socket) do
    SideNav.open socket
    Phoenix.View.render_to_string(SidenavView, "wiki.html", [])
  end

  defp render_to_string({bindings, user, page, template, socket}) do
    html = Phoenix.View.render_to_string(PageView, template, bindings)
    socket
    |> Query.update(:html, set: html, on: ".main-content")
    |> Query.update(:html, set: sidenav(socket), on: ".flex-nav section")
    |> Rebel.Core.async_js(active_link_js(page))
  end

  defp async_js(socket, nil), do: socket

  defp async_js(socket, js) do
    Rebel.Core.async_js(socket, js)
  end

  defp active_link_js(nil), do: nil
  defp active_link_js(page) do
    """
    $('.flex-nav .wrapper li').removeClass('active');
    $('.flex-nav li a[data-id="#{page.id}"]').parent().addClass('active');
    """
    |> String.replace("\n", "")
  end

  defp get_user(socket) do
    Accounts.get_user(socket.assigns.user_id, default_preload: true)
  end

  def new_page(socket, _sender, title \\ "") do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)

    render_to_string({[title: title], get_user(socket), nil, "new.html", socket})
    # sidenav(socket)
    # html = Phoenix.View.render_to_string(PageView, "new.html", [])
    # Rebel.Query.update(socket, :html, set: html, on: ".main-content")
  end

  def open_page(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)
    sidenav(socket)
    name = sender["dataset"]["name"]
    open(socket, name)
    # render_page(Page.get_by(title: name), socket)
  end

  defp open(socket, title) do
    render_page(Page.get_by(title: title), socket)
  end

  defp render_markdown(body, user) do
    case Earmark.as_html(body) do
      {:ok, body, _} -> body
      {:error, error} -> inspect(error)
    end
    |> MessageView.format_page(user)
    |> encode_custom_markdown()
  end

  defp render_page(page, socket) do
    user = get_user(socket)
    body = render_markdown(page.body, user) |> Phoenix.HTML.raw()

    render_to_string({[title: page.title, body: body, id: page.id], user, page, "show.html", socket})

    # html = Phoenix.View.render_to_string(PageView, "show.html", title: page.title, body: body, id: page.id)
    # Rebel.Query.update(socket, :html, set: html, on: ".main-content")
  end

  def create_page(socket, %{"form" => form} = _sender) do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)
    sidenav(socket)
    user = get_user(socket)

    resource_params = Helpers.normalize_params(form)["wiki"]
    # |> IO.inspect(label: "resource_params")

    case Page.create(user, resource_params) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page created successfully!))
        render_page(page, socket)
      {:error, changeset} ->
        errors = SharedView.format_errors(changeset)
        Client.toastr(socket, :error, gettext("Problem creating page: %{errors}", errors: errors))
    end
  end

  def edit_page(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)
    # user = Accounts.get_user socket.assigns.user_id, default_preload: true

    page = Page.get(sender["dataset"]["id"])

    # html = Phoenix.View.render_to_string(PageView, "edit.html", title: page.title, body: page.body, id: page.id)
    # Rebel.Query.update(socket, :html, set: html, on: ".main-content")
    render_to_string({
      [title: page.title, body: page.body, id: page.id],
      get_user(socket), page, "edit.html", socket})
  end

  def update_page(socket, %{"form" => form} = _sender) do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)

    resource_params = (Helpers.normalize_params(form)["wiki"])
    case Page.update(Page.get(form["id"]), resource_params) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page updated successfully.))
        render_page(page, socket)
      {:error, changeset} ->
        errors = SharedView.format_errors(changeset)
        Client.toastr(socket, :error, gettext("Problem updating page: %{errors}", errors: errors))
    end
  end

  def cancel_edit(socket, %{"form" => form} = sender) do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)
    # Rebel.Core.async_js(socket, ~s/$('.flex-nav.create-channel header').click()/)
    if id = form["id"] do
      render_page(Page.get(id), socket)
    else
      new_page(socket, sender)
    end
  end

  def preview_mode(socket, %{"form" => form} = sender) do
    resource_params = Helpers.normalize_params(form)["wiki"]

    body =
      resource_params["body"]
      |> render_markdown(get_user(socket))
      # |> Phoenix.HTML.safe_to_string()
      |> wrap_for_preview()
    Query.update(socket, :html, set: body, on: "#preview")
  end

  defp wrap_for_preview(html) do
    "<div class='content wiki markdown-body message preview'>" <> html <> "</div>"
  end

  defp encode_custom_markdown(body) do
    body
    |> encode_local_link()
    |> encode_remote_links()
  end

  defp encode_local_link(body) do
    Regex.replace(~r/\[\[(.*)\]\]/, body, fn _x, y ->
      class = if Page.get_by(title: y), do: "", else: " class='new-page'"
      "<a href='/wiki/#{y}'#{class}>#{y}</a>"
    end)
  end

  defp encode_remote_links(body) do
    Regex.replace(~r/(href=['"]http)/, body, "target='_blank' \\1")
  end
end
