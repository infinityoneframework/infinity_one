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
    do_insert(socket, item, to_map(opts), @no_broadcast)
  end

  def insert!(socket, item, opts) do
    do_insert(socket, item, to_map(opts), @broadcast)
  end

  def do_insert(socket, type, %{set: set, on: on}, fun) do
    method = jquery_method(:insert, type)
    js = build_js(on, method, set) <>
      update_events(on, method)
    fun.(socket, js)
    socket
  end

  def delete(socket, selector) when is_binary(selector) do
    do_delete(socket, selector, @no_broadcast)
  end
  def delete(socket, opts) do
    do_delete(socket, to_map(opts), @no_broadcast)
  end

  def delete!(socket, selector) when is_binary(selector) do
    do_delete(socket, selector, @broadcast)
  end
  def delete!(socket, opts) do
    do_delete(socket, to_map(opts), @broadcast)
  end

  def do_delete(socket, %{class: class, on: on}, fun) do
    method = jquery_method(:delete, :class)
    fun.(socket, build_js(on, method, class))
    socket
  end

  def do_delete(socket, %{closest: selector, on: on}, fun) do
    # method = jquery_method(:delete, :closest)
    fun.(socket, build_js(on, closest: [selector], remove: nil))
    socket
  end
  def do_delete(socket, selector, fun) when is_binary(selector) do
    fun.(socket, "$('#{selector}').remove();")
    socket
  end

  defp build_args([]), do: ""
  defp build_args(nil), do: ""
  defp build_args(list) when is_list(list) do
    list
    |> Enum.map(& "'" <> &1 <> "'")
    |> Enum.join(", ")
  end
  defp build_args(string) when is_binary(string) do
    "'#{string}'"
  end

  defp build_js(selector, list) when is_list(list) do
    Enum.reduce(list, "$('#{selector}')", fn {method, args}, acc ->
      acc <> ".#{method}(" <> build_args(args) <> ")"
    end)
    #"$('#{selector}').#{method}('#{value}').#{method1}();" #
    # |> IO.inspect(label: "build_js 4")
  end
  defp build_js(selector, {method, attr}, value) do
    "$('#{selector}').#{method}('#{attr}',#{escape_value(value)});" # |> IO.inspect(label: "build_js 1")
  end

  defp build_js(selector, method, value) when method in ~w(html replaceWith) do
    "$('#{selector}').#{method}(#{escape_value(value)});" # |> IO.inspect(label: "build_js 2")
  end
  defp build_js(selector, method, value) do
    "$('#{selector}').#{method}('#{value}');" # |> IO.inspect(label: "build_js 3")
  end

  defp to_map(opts), do: Enum.into(opts, %{})

  defp jquery_method(:update, :class), do: {"attr", "class"}
  defp jquery_method(:update, :text), do: "text"
  defp jquery_method(:update, :value), do: "val"
  defp jquery_method(:update, :html), do: "html"
  defp jquery_method(:update, {:class, :toggle}), do: "toggleClass"
  defp jquery_method(:update, :replaceWith), do: "replaceWith"

  defp jquery_method(:insert, :class), do: "addClass"
  defp jquery_method(:insert, :text), do: "text"
  defp jquery_method(:insert, :html), do: "text"

  defp jquery_method(:delete, :class), do: "removeClass"
  defp jquery_method(:delete, :closest), do: "closest"


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
  defp escape_value(value) do
    "#{Rebel.Core.encode_js(value)}"
  end
end
