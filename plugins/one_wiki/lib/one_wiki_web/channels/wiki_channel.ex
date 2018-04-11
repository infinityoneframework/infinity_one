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
  alias OneWiki.{Page, Subscription}
  alias InfinityOne.{Accounts, OnePubSub}
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

  ###############
  # handle_info

  def handle_info(:after_join, socket) do
    Logger.warn "Wiki after join"
    OnePubSub.subscribe("wiki:all", "update:page")
    OnePubSub.subscribe("wiki:all", "create:page")
    {:noreply, socket}
  end

  def handle_info({"wiki:all", "update:page", payload}, socket) do
    Logger.warn "update:page " <> inspect(payload)
    {:noreply, update_users_page_list(socket)}
  end

  def handle_info({"wiki:all", "create:page", payload}, socket) do
    Logger.warn "create:page " <> inspect(payload)
    # html = Phoenix.View.render_to_string(SidenavView, "pages.html", pages: Page.list())
    # Query.update(socket, :html, set: html, on: "aside.side-nav ul.wiki")
    {:noreply, update_users_page_list(socket)}
  end

  def handle_info(event, socket) do
    Logger.error("Unhandled event: " <> inspect(event))
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

  def handle_in(event, socket) do
    Logger.error("Unhandled event: " <> inspect(event))
    {:noreply, socket}
  end

  #########################
  # Rebel event handlers

  def new_page(socket, _sender, title \\ "") do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)

    hide_active_room(socket)
    render_to_string({[title: title], get_user(socket), nil, "new.html", socket})
    sidenav(socket)
    # html = Phoenix.View.render_to_string(PageView, "new.html", [])
    # Rebel.Query.update(socket, :html, set: html, on: ".main-content")
  end

  def open_page(socket, sender) do
    # Logger.warn "sender: " <> inspect(sender)
    # Logger.warn "assigns: " <> inspect(socket.assigns)
    # sidenav(socket)
    name = sender["dataset"]["name"]
    open(socket, name)
    # render_page(Page.get_by(title: name), socket)
  end

  def open_page_link(socket, sender) do
    name = sender["dataset"]["name"]
    socket
    |> hide_active_room()
    |> open(name)
  end

  def create_page(socket, %{"form" => form} = _sender) do
    user = get_user(socket)

    resource_params = Helpers.normalize_params(form)["wiki"]

    case Page.create(user, resource_params) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page created successfully!))
        OnePubSub.broadcast("wiki:all", "create:page", %{page: page})
        render_page(page, socket)
      {:error, changeset} ->
        page_action_error(socket, changeset, :creating)
    end
  end

  def edit_page(socket, sender) do
    page = Page.get(sender["dataset"]["id"])

    render_to_string({
      [title: page.title, body: page.body, id: page.id],
      get_user(socket), page, "edit.html", socket})
  end

  def update_page(socket, %{"form" => form} = _sender) do
    resource_params = (Helpers.normalize_params(form)["wiki"])
    case Page.update(get_user(socket), Page.get(form["id"]), resource_params) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page updated successfully.))
        OnePubSub.broadcast("wiki:all", "update:page", %{page: page})
        render_page(page, socket)
      {:error, changeset} ->
        page_action_error(socket, changeset, :updating)
    end
  end

  def delete_page(socket, sender) do
    id = sender["dataset"]["id"]
    user = get_user(socket)
    Logger.warn "delete_page #{id}"
    case Page.delete(user, id) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page deleted successfully.))
        OnePubSub.broadcast("wiki:all", "page:delete", %{page: page})
        socket |> update_users_page_list() |> close_sidenav()
      {:error, changeset} ->
        page_action_error(socket, changeset, :deleting)
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

  def subscribe_page(socket, sender) do
    Logger.warn "subscribe_page"
    user = get_user(socket)
    with id <- get_opts_id(socket, sender),
         false <- is_nil(id),
         {:ok, _} <- Subscription.create(%{user_id: user.id, page_id: id}) do
      socket |> update_users_page_list() |> close_sidenav() |> open_by_id(id)
    else
      error ->
        Logger.warn "error: " <> inspect(error)
        Client.toastr(socket, :error, ~s(Problem showing page.))
    end
  end

  def unsubscribe_page(socket, sender) do
    Logger.warn "unsubscribe_page"
    user = get_user(socket)
    with id <- get_opts_id(socket, sender),
         false <- is_nil(id),
         {:ok, _} <- socket |> get_user() |> Subscription.delete(id) do
      socket |> update_users_page_list()
    else
      error ->
        Logger.warn "error: " <> inspect(error)
        Client.toastr(socket, :error, ~s(Problem hiding page.))
    end
  end

  def hide_page(socket, sender) do
    Logger.warn "hide_page"
    user = get_user(socket)
    with id <- get_opts_id(socket, sender),
         false <- is_nil(id),
         {:ok, _} <- Subscription.hide_page(user, id) do
      socket |> update_users_page_list()
    else
      error ->
        Logger.warn "error: " <> inspect(error)
        Client.toastr(socket, :error, ~s(Problem hiding page.))
    end
  end

  def unhide_page(socket, sender) do
    Logger.warn "unhide_page"
    user = get_user(socket)
    with id <- get_opts_id(socket, sender),
         false <- is_nil(id),
         {:ok, _} <- Subscription.unhide_page(user, id) do
      socket |> update_users_page_list() |> close_sidenav() |> open_by_id(id)
    else
      error ->
        Logger.warn "error: " <> inspect(error)
        Client.toastr(socket, :error, ~s(Problem showing page.))
    end
  end

  def show_page(socket, sender) do
    Logger.warn "show_page: " <> inspect(sender)
    id = get_opts_id(socket, sender)
    Logger.warn "id: " <> inspect(id)
    socket
    |> close_sidenav()
    |> open_by_id(id)
  end

  def more_pages(socket, sender) do
    Logger.warn "more pages"
    sidenav(socket)
  end

  #########################
  # Private helpers

  defp get_opts_id(socket, sender) do
    Rebel.Core.exec_js!(socket, """
      let $this = $('#{Rebel.Core.this(sender)}');
      $this.closest('[data-id]').attr('data-id') || $this.parent().prev().attr('data-id');
      """ |> String.replace("\n", "") |> IO.inspect(label: "get_opts_id_js"))
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

  defp sidenav(socket) do
    SideNav.open socket
    user = get_user(socket)
    pages = get_pages_with_subscriptions(user)
    html = Phoenix.View.render_to_string(SidenavView, "wiki.html", user: user, pages: pages)
    Query.update(socket, :html, set: html, on: ".flex-nav")
  end

  def close_sidenav(socket) do
    Rebel.Query.execute(socket, :click, on: ".side-nav .arrow.close")
  end

  defp get_pages_with_subscriptions(user) do
    subscriptions = Subscription.list_by(user_id: user.id)
    Enum.map(Page.list(), fn page ->
      page
      |> Map.from_struct()
      |> Map.put(:subscription, Enum.find(subscriptions, & &1.page_id == page.id))
    end)
  end

  defp render_to_string({bindings, user, page, template, socket}) do
    html = Phoenix.View.render_to_string(PageView, template, bindings)
    length = Rebel.Core.exec_js!(socket, ~s/$('.page-container.page-home.page-static').length/)
    if length == 0 do
      Rebel.Query.insert(socket, html, append: ".main-content-flex")
    else
      Query.update(socket, :replaceWith, set: html, on: ".page-container.page-home.page-static")
    end
    |> Rebel.Core.async_js(active_link_js(page))
  end

  defp async_js(socket, nil), do: socket

  defp async_js(socket, js) do
    Rebel.Core.async_js(socket, js)
  end

  defp active_link_js(nil), do: nil
  defp active_link_js(page) do
    """
    $('.page-link').removeClass('active');
    $('section.wiki li.active').removeClass('active');
    $('li a[data-name="#{page.title}"]').parent().addClass('active');
    """
    |> String.replace("\n", "")
  end

  defp get_user(socket) do
    Accounts.get_user(socket.assigns.user_id, default_preload: true)
  end

  defp open_by_id(socket, id) do
    render_page(Page.get_by(id: id), socket)
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

  defp hide_active_room(socket) do
    Rebel.Core.async_js(socket, """
      let channelId = $('.room-link.active a.open-room[data-id]').attr('data-id');
      console.log('channelId', channelId);
      if (channelId) {
        $(`#chat-window-${channelId}`).hide();
        $('.room-link.active').removeClass('active');
      }
      $('#flex-tabs').hide();
      """ |> String.replace("\n", ""))
  end

  defp update_users_page_list(socket) do
    # user = get_user(socket)
    pages = socket |> get_user() |> SidenavView.get_pages()
    count = ~s/"(#{length(pages)})"/
    html = Phoenix.View.render_to_string(SidenavView, "pages.html", pages: pages)
    socket
    |> Query.update(:html, set: html, on: "aside.side-nav ul.wiki")
    |> Rebel.Core.async_js(~s/$('h3.add-room.wiki .room-count-small').text(#{count})/)
  end

  defp page_action_error(socket, changeset, action) do
    errors =
      case changeset do
        %Ecto.Changeset{} = changeset ->
          SharedView.format_errors(changeset)
        string when is_binary(string) ->
          string
      end
    Client.toastr(socket, :error, gettext("Problem %{action} page: %{errors}",
      errors: errors, action: to_string(action)))
  end

end
