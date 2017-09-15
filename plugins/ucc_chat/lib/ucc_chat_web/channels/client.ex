defmodule UccChatWeb.Client do
  import UcxUccWeb.Utils
  import Rebel.{Query, Core}, warn: false

  require Logger
  # alias Rebel.Element

  def send_js(socket, js) do
    exec_js socket, strip_nl(js)
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

  defdelegate render_to_string(view, templ, bindings), to: Phoenix.View
  defdelegate insert_html(socket, selector, position, html), to: Rebel.Element
end
