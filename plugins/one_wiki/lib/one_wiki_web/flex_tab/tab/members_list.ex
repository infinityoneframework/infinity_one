defmodule OneWikiWeb.FlexBar.Tab.MembersList do
  @moduledoc """
  OneWiki Info Flex Tab.
  """
  use OneChatWeb.FlexBar.Helpers, except: [user_info: 2]
  use OneLogger

  alias InfinityOne.{TabBar.Tab}
  alias InfinityOne.{TabBar}
  alias OneWikiWeb.FlexBarView
  # alias OneChatWeb.RebelChannel.Client
  alias OneWiki.Page

  @doc """
  Show Info about the page.
  """
  @spec add_buttons() :: no_return
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[wiki],
      "wiki-members-list",
      ~g"Members List",
      "icon-users",
      FlexBarView,
      "members_list.html",
      20,
      [
        model: Page,
        prefix: "page"
      ]
    )
  end

  @doc """
  Callback for the rendering bindings for the MembersList panel.
  """
  def args(socket, {user_id, _channel_id, _, _,}, opts) do
    current_user = Helpers.get_user!(user_id)

    if page = socket.assigns[:page] do
      {user, user_mode} =
        case opts["username"] do
          nil ->
            {Helpers.get_user!(user_id), false}
          username ->
            {Helpers.get_user_by_name(username, preload: [:roles, user_roles: :role]), true}
        end

      users = Page.get_all_page_online_users(page)
      total_count = page |> Page.get_all_users() |> length

      user_info =
        page
        |> __MODULE__.user_info(user_mode: user_mode, view_mode: true)
        |> Map.put(:total_count, total_count)

      {[users: users, user: user, user_info: user_info,
       page_id: page.id, page: page, current_user: current_user], socket}
    else
      nil
    end
  end

  def user_args(socket, user_id, _channel_id, username) do
    preload = InfinityOne.Hooks.user_preload [:roles, user_roles: :role]
    if user = Helpers.get_user_by_name(username, preload: preload) do
      {[
        user: user,
        user_info: __MODULE__.user_info(%{}, user_mode: true, view_mode: true),
        current_user: Helpers.get_user(user_id)
      ], socket}
    else
      nil
    end
  end

  def user_info(_page, opts \\ []) do
    show_admin = opts[:admin] || false
    user_mode = opts[:user_mode] || false
    view_mode = opts[:view_mode] || false

    %{direct: false, show_admin: show_admin, blocked: false, user_mode: user_mode, view_mode: view_mode}
  end

  # this is needed since we are overriding below
  def open(socket, {user_id, channel_id, tab, sender}, nil) do
    super(socket, {user_id, channel_id, tab, sender}, nil)
  end

  # # TODO: Figure out how to have this detect this.
  # def open(socket, {current_user_id, channel_id, tab, sender}, %{"view" => "video"} = args) do
  #   WebrtcMembersList.open(socket, {current_user_id, channel_id, tab, sender}, args)
  # end

  def open(socket, {user_id, _channel_id, tab, sender}, %{"view" => "user"} = args) do
    username = args["username"]
    channel_id = socket.assigns.channel_id

    case user_args(socket, user_id, channel_id, username) do
      {args, socket} ->
        html =
          FlexBarView
          |> Phoenix.View.render_to_string("user_card.html", args)
          |> String.replace(~s('), ~s(\\'))
          |> String.replace("\n", " ")

        selector = ".flex-tab-container .user-view"

        socket
        |> super({user_id, channel_id, tab, sender}, nil)
        |> async_js(~s/$('#{selector}').replaceWith('#{html}'); Rebel.set_event_handlers('#{selector}')/)
      _ ->
        socket
    end
  end

  def open(socket, _tuple, _args) do
    socket
  end

  def resource_id(socket, _, _) do
    Map.get(socket.assigns[:page] || %{}, :id)
  end

  @doc """
  Handle the cancel button.
  """
  def flex_form_cancel(socket, _sender) do
    socket
  end

  def get_opts do
    %{
    }
  end

end
