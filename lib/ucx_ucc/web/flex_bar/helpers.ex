defmodule UcxUcc.Web.FlexBar.Helpers do
  defmacro __using__(_) do
    quote do
      use UcxUcc.Web.Gettext

      import unquote(__MODULE__)
      import Rebel.Query
      import Rebel.Core

      alias UcxUcc.TabBar

      def open(socket, _ch, tab, panel, params) do
        user_id = socket.assigns[:user_id]
        channel_id = socket.assigns[:channel_id]
        case tab[:template] do
          nil -> %{}
          templ ->
            args = args user_id, channel_id, panel, params
            html = Phoenix.View.render_to_string(tab.view, templ, args)

            js = [
              "$('section.flex-tab').parent().addClass('opened')",
              "$('.tab-button.active').removeClass('active')",
              set_tab_button_active_js(tab.id)
            ] |> Enum.join(";")

            socket
            |> update(:html, set: html, on: "section.flex-tab")
            |> exec_js(js)
        end
        socket
      end

      def close(socket, _ch, _tab, _panel, _params) do
        exec_js(socket, """
          $('section.flex-tab').parent().removeClass('opened')
          $('.tab-button.active').removeClass('active')
          """)
        socket
      end

      def args(_, _, _, _), do: []

      defoverridable [open: 5, close: 5, args: 4]
    end
  end

  import Rebel.Core

  def set_tab_button_active_js(id) do
    get_tab_button_js(id) <> ".hasClass('active')"
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

