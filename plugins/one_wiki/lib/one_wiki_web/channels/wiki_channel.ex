defmodule OneWikiWeb.WikiChannel do
  use OneLogger
  use InfinityOne
  use OneWikiWeb, :channel

  use Rebel.Channel, name: "wiki", controllers: [
    OneChatWeb.ChannelController,
  ], intercepts: [
  ]

  import Rebel.Core, only: []
  alias OneChat.ServiceHelpers, as: Helpers
  alias OneWikiWeb.{PageView, SidenavView}
  alias OneWiki.{Page, Subscription}
  alias InfinityOne.{Accounts, OnePubSub}
  alias OneChatWeb.RebelChannel.Client
  alias OneChatWeb.{SharedView, MessageView, UserChannel}
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
  # handle_out


  ###############
  # handle_info

  def handle_info(:after_join, socket) do
    # Logger.warn "Wiki after join"
    OnePubSub.subscribe("wiki:all", "update:page")
    OnePubSub.subscribe("wiki:all", "create:page")
    {:noreply, socket}
  end

  def handle_info({"wiki:all", "update:page", _payload}, socket) do
    {:noreply, update_users_page_list(socket)}
  end

  def handle_info({"wiki:all", "create:page", _payload}, socket) do
    {:noreply, update_users_page_list(socket)}
  end

  def handle_info(event, socket) do
    Logger.error("Unhandled event: " <> inspect(event))
    {:noreply, socket}
  end

  ###############
  # handle_in

  def handle_in("open_room", %{"title" => title} = payload, socket) do
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
    hide_active_room(socket)
    render_to_string({[title: title, format: "markdown"], get_user(socket), nil, "new.html", socket})
    sidenav(socket)
  end

  def open_page(socket, sender) do
    name = sender["dataset"]["name"]
    open(socket, name)
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
        Subscription.create(%{user_id: user.id, page_id: page.id})
        Client.toastr(socket, :success, ~g(Page created successfully!))
        OnePubSub.broadcast("wiki:all", "create:page", %{page: page})
        render_page(page, update_sidenav(socket))
      {:error, changeset} ->
        page_action_error(socket, changeset, :creating)
    end
  end

  def edit_page(socket, sender) do
    page = Page.get(sender["dataset"]["id"])

    close_flex_tab(socket)

    render_to_string({
      [title: page.title, body: page.body, id: page.id, format: "markdown"],
      get_user(socket), page, "edit.html", socket})
  end

  defp close_flex_tab(socket) do
    Rebel.Core.async_js(socket, ~s/$('.tab-button.active[data-id="wiki_info"]').click()/)
  end

  def update_page(socket, %{"form" => form} = _sender) do
    resource_params = (Helpers.normalize_params(form)["wiki"])
    case Page.update(get_user(socket), Page.get(form["id"]), resource_params) do
      {:ok, page} ->
        Client.toastr(socket, :success, ~g(Page updated successfully.))
        OnePubSub.broadcast("wiki:all", "update:page", %{page: page})
        render_page(page, update_sidenav(socket))
      {:error, changeset} ->
        page_action_error(socket, changeset, :updating)
    end
  end

  def delete_page(socket, sender) do
    id = sender["dataset"]["id"]
    user = get_user(socket)
    case Page.delete(user, id) do
      {:ok, page} ->
        async_js(socket, ~s/if ($('#flex-tabs.static-pages.opened')) { $('.close-flex-tab').click() }/)
        Client.toastr(socket, :success, ~g(Page deleted successfully.))
        OnePubSub.broadcast("wiki:all", "page:delete", %{page: page})
        UserChannel.put_assign(socket.assigns.user_id, :page, nil)
        UserChannel.put_assign(socket.assigns.user_id, :last_page_id, nil)
        socket |> update_users_page_list() |> close_sidenav()
      {:error, changeset} ->
        page_action_error(socket, changeset, :deleting)
    end

  end

  def cancel_edit(socket, %{"form" => form} = sender) do
    if id = form["id"] do
      render_page(Page.get(id), socket)
    else
      new_page(socket, sender)
    end
  end

  def preview_mode(socket, %{"form" => form}) do
    resource_params = Helpers.normalize_params(form)["wiki"]

    body =
      resource_params["body"]
      |> render_markdown(get_user(socket))
      |> wrap_for_preview()
    Query.update(socket, :html, set: body, on: "#preview")
  end

  def subscribe_page(socket, sender) do
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
    # Logger.warn "unsubscribe_page"
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
    # Logger.warn "hide_page"
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
    id = get_opts_id(socket, sender)
    socket
    |> close_sidenav()
    |> open_by_id(id)
  end

  def more_pages(socket, _sender) do
    sidenav(socket)
  end

  def show_revision(socket, sender) do
    commit = String.trim(sender["text"])
    page = Rebel.get_assigns(socket, :page)
    {title, markup} = OneWiki.Git.show(commit)
    contents = Earmark.as_html!(markup)

    html = """
      <div class="markdown-body version-preview wiki">
        <header>
          #{title}
          <a href="#" rebel-click="close_file_preview" rebel-channel="wiki">
            <span class="right"><i class="icon-cancel"></i></span>
          </a>
        </header>
        <section class="preview-contents">
          #{contents}
        </section>
      </div>
      """
    socket
    |> Rebel.Query.insert(html, append: "body")
    |> Rebel.Core.async_js(~s/$('.body-mask').show();/)
  end

  def close_file_preview(socket, _sender) do
    async_js(socket, ~s/$('.version-preview').remove();$('.body-mask').hide();/)
  end

  #########################
  # Private helpers

  defp get_opts_id(socket, sender) do
    Rebel.Core.exec_js!(socket, """
      let $this = $('#{Rebel.Core.this(sender)}');
      $this.closest('[data-id]').attr('data-id') || $this.parent().prev().attr('data-id');
      """ |> String.replace("\n", ""))
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
    do_sidenav(socket)
  end

  defp do_sidenav(socket) do
    user = get_user(socket)
    pages = get_pages_with_subscriptions(user)
    html = Phoenix.View.render_to_string(SidenavView, "wiki.html", user: user, pages: pages)
    Query.update(socket, :html, set: html, on: ".flex-nav")
  end

  defp update_sidenav(socket) do
    closed? = Rebel.Core.exec_js!(socket, ~s/$('.flex-nav').hasClass('animated-hidden')/)
    unless closed? do
      do_sidenav(socket)
    end
    socket
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

  defp render_to_string({bindings, _user, page, template, socket}) do
    html = Phoenix.View.render_to_string(PageView, template, bindings)
    length = Rebel.Core.exec_js!(socket, ~s/$('.page-container.page-home.page-static').length/)
    if length == 0 do
      Rebel.Query.insert(socket, html, before: "#flex-tabs")
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
    page = Page.get_by(title: title)
    render_page(page, socket)

    if page do
      OnePubSub.broadcast "user:" <> socket.assigns.user_id, "room:join",
        %{resource_id: page.id, last_resource_key: :last_page_id}
    end
    socket
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
    last_page_id = socket |> Rebel.get_assigns(:page, %{}) |> Map.get(:id)
    UserChannel.put_assign(socket.assigns.user_id, :page, page)
    UserChannel.put_assign(socket.assigns.user_id, :last_page_id, last_page_id)
    Rebel.put_assigns(socket, :page, page)
    user = get_user(socket)
    body = render_markdown(page.body, user) |> Phoenix.HTML.raw()

    render_to_string({[title: page.title, body: body, id: page.id], user, page, "show.html", socket})
  end

  defp hide_active_room(socket) do
    socket
    |> render_flex_tabs()
    |> Rebel.Core.async_js("""
      let channelId = $('.room-link.active a.open-room[data-id]').attr('data-id');
      console.log('channelId', channelId);
      if (channelId) {
        $(`#chat-window-${channelId}`).hide();
        $('.room-link.active').removeClass('active');
      }
      """ |> String.replace("\n", ""))
  end

  defp render_flex_tabs(socket) do
    html = Phoenix.View.render_to_string(OneUiFlexTabWeb.TabBarView, "index.html", groups: ~w(wiki))
    socket
    |> async_js(~s/OneChat.Wiki.openStaticPage()/)
    |> Query.update(:html, set: html, on: "#flex-tabs")
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
        %Git.Error{message: message} ->
          "Git: #{message}"
      end
    Client.toastr(socket, :error, gettext("Problem %{action} page: %{errors}",
      errors: errors, action: to_string(action)))
  end

end
