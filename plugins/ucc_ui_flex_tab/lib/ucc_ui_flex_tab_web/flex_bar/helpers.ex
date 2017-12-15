defmodule UccUiFlexTabWeb.FlexBar.Helpers do
  @moduledoc """
  Add FlexBar support to a Tab Module.

  Use this module to include the default callbacks for a registered Tab.

  Each of the callbacks are override-able to add custom behavior.

  ## Example:

  The following is an example Tab module showing the basic usage.

      defmodule UccChatWeb.FlexBar.Tab.StaredMessage do
        use UccChatWeb.FlexBar.Helpers

        alias UccChat.StaredMessage
        alias UcxUcc.TabBar.Tab

        def add_buttons do
          TabBar.add_button Tab.new(
            __MODULE__,
            ~w[channel direct im],
            "stared-messages",
            ~g"Stared Messages",
            "icon-star",
            View,
            "stared_messages.html",
            80)
        end

        def args(socket, {user_id, channel_id, _, _}, _) do
          stars =
            channel_id
            |> StaredMessage.get_by_channel_id_and_user_id(user_id)
            |> do_messages_args(user_id, channel_id)
          {[stars: stars], socket}
        end
      end
  """

  import Rebel.Query
  alias UcxUcc.TabBar

  require Logger

  defmacro __using__(_) do
    quote do
      use UcxUccWeb.Gettext

      import unquote(__MODULE__)
      import Rebel.Query
      import Rebel.Core

      alias UcxUcc.TabBar
      alias TabBar.Ftab

      require Logger

      @type socket :: Phoenix.Socket.t
      @type id     :: String.t
      @type tab    :: UcxUcc.TabBar.Tab.t
      @type args   :: Map.t | nil

      @doc """
      Open a tab window.

      Fetches the args (override-able), renders the template and updates
      the browser with some javascript.

      Override to add custom behaviour, like:

          def open(socket, user_id, channel_id, tab, args) do
            # Some custom code
            super(socket, user_id, channel_id, tab, args)
          end
      """
      @spec open(socket, {id, id, tab, map}, args) :: socket
      def open(socket, {user_id, channel_id, tab, sender}, args) do
        case tab.template do
          "" -> socket
          templ ->
            handle_on_change(socket, sender)

            {args, socket} = args socket, {user_id, channel_id, nil, sender}, args

            html = Phoenix.View.render_to_string(tab.view, templ, args)

            js = [
              "$('section.flex-tab-main').parent().addClass('opened')",
              "$('.tab-button.active').removeClass('active')",
              set_tab_button_active_js(tab.id),
              add_name_to_section_js(tab.id)
            ] |> Enum.join(";")

            socket
            |> update(:html, set: html, on: "section.flex-tab-main")
            |> exec_js(js)

            socket
        end
      end

      @doc """
      Callback when leaving a given tab.

      Allows the tab to cleanup before the next tab is opened.

      Override-able
      """
      def on_change(socket, sender) do
        socket
      end

      @doc """
      Close a tab.

      Default behaviour is to just close hide the window with javascript.
      You can override to customize the behaviour. Don't forget to call

          def close(socket) do
            # Custom code ...
            super(socket)
          end

      at the end of your override.
      """
      @spec close(socket, map) :: socket
      def close(socket, _sender) do
        exec_js(socket, """
          $('section.flex-tab').parent().removeClass('opened')
          $('.tab-button.active').removeClass('active')
          """)
      end

      @doc """
      Get the args for an open.

      Override to implement.
      """
      @spec args(socket, {id, id, any, map}, map | nil) :: {Keyword.t, socket}
      def args(socket, {_, _, _, _}, _), do: {[], socket}

      @doc """
      Callback when a form has been successfully updated

      Override to implement the callback.
      """
      @spec notify_update_success(socket, tab, map, map) :: socket
      def notify_update_success(socket, tab, _sender, _opts), do: socket

      defoverridable [open: 3, close: 2, args: 3, notify_update_success: 4, on_change: 2]
    end
  end

  import Rebel.Core

  @type socket :: Phoenix.Socket.t

  @doc """
  Get the Javascript for marking a tab button active.

  Given a button id, returns the JS to add the `active` class.
  """
  @spec set_tab_button_active_js(String.t) :: String.t
  def set_tab_button_active_js(id) do
    get_tab_button_js(id) <> ".addClass('active')"
  end

  @doc """
  Get the Javascript to fetch a tab button from the client.
  """
  @spec get_tab_button_js(String.t) :: String.t
  def get_tab_button_js(id) do
    ~s/$('.tab-button[data-id="#{id}"]')/
  end

  @doc """
  Get the DOM class of the tab container.
  """
  @spec tab_container() :: String.t
  def tab_container(), do: ".flex-tab-container"

  @doc """
  Create the Javascript to set `data-fun` for the current control.

  Use this function to return the JS to set the `data-fun` attribute. The
  element is give by the rebel-id from the sender map.
  """
  @spec exec_update_fun(socket, map, String.t) :: socket
  def exec_update_fun(socket, sender, name) do
    js = ~s/$('#{this(sender)}')[0].dataset['fun'] = '#{name}'/
    exec_js socket, js
    socket
  end

  @doc """
  Get the Javascript to dd a name to the opened tab.

  The name is used do identify the open tab, so this is needed for opining
  a new tab.
  """
  @spec add_name_to_section_js(String.t) :: String.t
  def add_name_to_section_js(name) do
    "$('.flex-tab-container.opened section.flex-tab')[0].dataset['tab'] = '#{name}'"
  end

  @doc """
  Callback helper to notify tabs of a state change.

  This callback allows to tabs to perform post change actions.
  """
  @spec notify_on_change(nil | String.t | atom, socket, map) :: any
  def notify_on_change(nil, _socket, _sender), do: nil
  def notify_on_change(id, socket, sender) do
    tab = TabBar.get_button! id
    if module = tab.module do
      apply module, :on_change, [socket, sender]
    end
  end

  @doc """
  Callback to handle change notifications.
  """
  @spec handle_on_change(socket, map) :: socket
  def handle_on_change(socket, sender) do
    socket
    |> select(data: "id", from: ".tab-button.active")
    |> notify_on_change(socket, sender)
    socket
  end
end

