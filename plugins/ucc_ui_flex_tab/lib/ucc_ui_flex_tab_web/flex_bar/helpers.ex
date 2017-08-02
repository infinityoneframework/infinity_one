defmodule UccUiFlexTabWeb.FlexBar.Helpers do
  @moduledoc """


  """
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
      @spec open(socket, id, id, tab, args) :: socket
      def open(socket, user_id, channel_id, tab, args) do
        case tab.template do
          "" -> socket
          templ ->
            {args, socket} = args socket, user_id, channel_id, nil, args
            # IO.inspect args, label: "... args"
            html = Phoenix.View.render_to_string(tab.view, templ, args)

            # Logger.warn "html: #{html}"
            js = [
              "$('section.flex-tab').parent().addClass('opened')",
              "$('.tab-button.active').removeClass('active')",
              set_tab_button_active_js(tab.id)
            ] |> Enum.join(";")

            socket
            |> update(:html, set: html, on: "section.flex-tab")
            |> exec_js(js)

            socket
        end
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
      @spec close(socket) :: socket
      def close(socket) do
        exec_js(socket, """
          $('section.flex-tab').parent().removeClass('opened')
          $('.tab-button.active').removeClass('active')
          """)
        socket
      end

      @doc """
      Get the args for an open.

      Override to implement.
      """
      @spec args(socket, id, id, any, map | nil) :: {Keyword.t, socket}
      def args(socket, _, _, _, _), do: {[], socket}

      @doc """
      Callback when a form has been successfully updated

      Override to implement the callback.
      """
      @spec notify_update_success(socket, tab, map, map) :: socket
      def notify_update_success(socket, tab, _sender, _opts), do: socket

      defoverridable [open: 5, close: 1, args: 5, notify_update_success: 4]
    end
  end

  import Rebel.Core

  def set_tab_button_active_js(id) do
    get_tab_button_js(id) <> ".addClass('active')"
  end

  def get_tab_button_js(id) do
    ~s/$('.tab-button[data-id="#{id}"]')/
  end

  def tab_container(), do: ".flex-tab-container"

  def exec_update_fun(socket, sender, name) do
    js = ~s/$('#{this(sender)}')[0].dataset['fun'] = '#{name}'/
    exec_js socket, js
    socket
  end

end

