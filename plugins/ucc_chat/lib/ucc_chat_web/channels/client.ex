defmodule UccChatWeb.Client do
  import UcxUccWeb.Utils
  import Rebel.{Query, Core}, warn: false

  require Logger
  # alias Rebel.Element

  defmacro __using__(_) do
    quote do
      import UcxUccWeb.Utils
      defdelegate send_js(socket, js), to: unquote(__MODULE__)
      defdelegate send_js!(socket, js), to: unquote(__MODULE__)
      defdelegate closest(socket, selector, class, attr), to: unquote(__MODULE__)
      defdelegate append(socket, selector, html), to: unquote(__MODULE__)
      defdelegate broadcast!(socket, event, bindings), to: Phoenix.Channel
      defdelegate render_to_string(view, templ, bindings), to: Phoenix.View
      defdelegate insert_html(socket, selector, position, html), to: Rebel.Element
      defdelegate query_one(socket, selector, prop), to: Rebel.Element
      defdelegate toastr!(socket, which, message), to: UccChatWeb.RebelChannel.Client
      defdelegate toastr(socket, which, message), to: UccChatWeb.RebelChannel.Client
    end
  end

  def send_js(socket, js) do
    exec_js socket, strip_nl(js)
  end

  def send_js!(socket, js) do
    exec_js! socket, strip_nl(js)
  end

  # not sure how to do this
  def closest(socket, selector, class, attr) do
    IO.inspect selector
    exec_js! socket, """
      var el = document.querySelector('#{selector}');
      console.log('selector', '#{selector}');
      console.log('el', el);
      el = el.closest('#{class}');
      if (el) {
        el.getAttribute('#{attr}');
      } else {
        null;
      }
      """
  end

  def append(socket, selector, html) do
    Rebel.Query.insert socket, html, append: selector
  end

  defdelegate broadcast!(socket, event, bindings), to: Phoenix.Channel
  defdelegate render_to_string(view, templ, bindings), to: Phoenix.View
  defdelegate insert_html(socket, selector, position, html), to: Rebel.Element
  defdelegate toastr!(socket, which, message), to: UccChatWeb.RebelChannel.Client
  defdelegate toastr(socket, which, message), to: UccChatWeb.RebelChannel.Client
end
