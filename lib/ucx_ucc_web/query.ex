defmodule UcxUccWeb.Query do

  @broadcast             &Rebel.Core.broadcast_js/2
  @no_broadcast          &Rebel.Core.async_js/2
  @html_modifiers        ~r/html|append|before|after|insertAfter|insertBefore|htmlPrefilter|prepend|replaceWith|wrap/i

  def update(socket, item, opts) do
    do_update(socket, item, to_map(opts), @no_broadcast)
  end

  def update!(socket, item, opts) do
    do_update(socket, item, to_map(opts), @broadcast)
  end

  def do_update(socket, type, %{set: set, on: on}, fun) do
    method = jquery_method(:update, type)
    js = build_js(on, method, set) <>
      update_events(on, method)
    fun.(socket, js)
    socket
  end

  def do_update(socket, type, %{toggle: set, on: on}, fun) do
    method = jquery_method(:update, {type, :toggle})
    fun.(socket, build_js(on, method, set))
  end

  def insert(socket, item, opts) do
    do_update(socket, item, to_map(opts), @no_broadcast)
  end

  def insert!(socket, item, opts) do
    do_update(socket, item, to_map(opts), @broadcast)
  end

  def do_insert(socket, type, %{set: set, on: on}, fun) do
    method = jquery_method(:insert, type)
    fun.(socket, build_js(on, method, set))
    socket
  end

  def delete(socket, opts) do
    do_delete(socket, to_map(opts), @no_broadcast)
  end

  def do_delete(socket, %{class: class, on: on}, fun) do
    method = jquery_method(:delete, :class)
    fun.(socket, build_js(on, method, class))
    socket
  end

  defp build_js(selector, {method, attr}, value) do
    "$('#{selector}').#{method}('#{attr}',#{escape_value(value)});"
  end

  defp build_js(selector, method, value) when method in ~w(html replaceWith) do
    "$('#{selector}').#{method}(#{escape_value(value)});"
  end
  defp build_js(selector, method, value) do
    "$('#{selector}').#{method}('#{value}');"
  end

  defp to_map(opts), do: Enum.into(opts, %{})

  defp jquery_method(:update, :class), do: {"attr", "class"}
  defp jquery_method(:update, :text), do: "text"
  defp jquery_method(:update, :html), do: "html"
  defp jquery_method(:update, {:class, :toggle}), do: "toggleClass"
  defp jquery_method(:update, :replaceWith), do: "replaceWith"

  defp jquery_method(:insert, :class), do: "addClass"
  defp jquery_method(:insert, :text), do: "text"
  defp jquery_method(:insert, :html), do: "text"

  defp jquery_method(:delete, :class), do: "removeClass"

  defp update_events(selector, {method, _}), do: update_events(selector, method)
  defp update_events(selector, method) do
    if Regex.match? @html_modifiers, method do
      "Rebel.set_event_handlers('#{selector}');"
    else
      ""
    end
  end

  defp escape_value(value) when is_boolean(value),  do: "#{inspect(value)}"
  defp escape_value(value) when is_nil(value),      do: ~s("")
  defp escape_value(value)                         do
    "#{Rebel.Core.encode_js(value)}"
  end
end
