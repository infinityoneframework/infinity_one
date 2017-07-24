defmodule UccUiFlexTab.Web.FlexBar.Helpers do
  @moduledoc """


  """
  defmacro __using__(_) do
    quote do
      use UcxUcc.Web.Gettext

      import unquote(__MODULE__)
      import Rebel.Query
      import Rebel.Core

      alias UcxUcc.TabBar
      alias TabBar.Ftab

      require Logger

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

      def close(socket) do
        exec_js(socket, """
          $('section.flex-tab').parent().removeClass('opened')
          $('.tab-button.active').removeClass('active')
          """)
        socket
      end

      def args(socket, _, _, _, _), do: {[], socket}

      defoverridable [open: 5, close: 1, args: 5]
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

