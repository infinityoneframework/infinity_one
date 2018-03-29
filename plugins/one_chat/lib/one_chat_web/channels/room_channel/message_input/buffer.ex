defmodule OneChatWeb.RoomChannel.MessageInput.Buffer do
  use OneChatWeb.RoomChannel.Constants

  alias OneChatWeb.RoomChannel.MessageInput
  require Logger

  def new(head, tail, start, len, buffer) do
    %{head: head, tail: tail, start: start, len: len, buffer: buffer}
  end

  def add_buffer_state(context, sender, key) do
    state = get_buffer_state(sender, key)
    Map.put(context, :state, state)
  end

  def get_buffer_state(%{"caret" => %{"start" => 0}} = _sender, key) when key in [@bs, @left_arrow] do
    :ignore
  end

  def get_buffer_state(%{"text_len" => len, "caret" => %{"start" => len}} = _sender, @right_arrow) do
    :ignore
  end

  def get_buffer_state(sender, @bs) do
    value = sender["value"]
    {start, _} = caret sender
    {head, tail} = String.split_at value, start
    head = String.replace(head, ~r/.$/, "")
    new head, tail, start - 1, sender["text_len"] - 1, head <> tail
  end

  def get_buffer_state(%{"value" => value} = sender, @left_arrow) do
    {start, _} = caret sender
    start = start - 1
    {head, tail} = String.split_at value, start
    new head, tail, start, sender["text_len"], value
  end

  def get_buffer_state(%{"value" => value} = sender, @right_arrow) do
    {start, _} = caret sender
    start = start + 1
    {head, tail} = String.split_at value, start
    new head, tail, start, sender["text_len"], value
  end

  def get_buffer_state(sender, key) when key in @special_keys do
    value = sender["value"]
    {start, _} = caret sender
    len = sender["text_len"] || String.length value
    if len == start do
      # cursor at the end of the buffer
      new value, "", start, sender["text_len"], value
    else
      {head, tail} = String.split_at value, sender["caret"]["start"]
      new head, tail, start, sender["text_len"], value
    end
  end

  # cursor at the end. Append the char
  def get_buffer_state(%{"text_len" => len, "caret" => %{"start" => len, "end" => len}} = sender, key) do
    value = sender["value"] <> key
    new value, "", len + 1, len + 1, value
  end

  # cursor not at the end. Insert the char
  def get_buffer_state(sender, key) do
    value = sender["value"]
    {start, _} = caret sender

    len = sender["text_len"] + 1

    {head, tail} = String.split_at value, start
    head = head <> key
    buffer = head <> tail

    new head, tail, start + 1, len, buffer
  end

  defp caret(%{"caret" => %{"start" => start, "end" => finish}}) do
    {start, finish}
  end

  def check_popup_state(app, _key, buffer, text_len, caret) do
    pos =
      case caret["start"] do
        start when start > 0 -> start - 1
        _ -> 0
      end
    result =
      buffer
      |> get_matched_buffer(pos, text_len)
      |> match_all_patterns
      |> case do
        nil ->
          if app, do: :close, else: :ok
        {match, app_key} -> {:open, {match, @app_lookup[app_key]}}
      end
    # Logger.error "key: #{inspect key}, buffer: #{inspect buffer}, text_len: #{text_len}, caret: #{inspect caret}, result: #{inspect result}"
    result
  end

  def get_matched_buffer(buffer, pos, len) do
    if pos < len do
      String.slice(buffer, 0, pos)
    else
      buffer
    end
  end

  def match_app_pattern(buffer) do
    case Regex.run @match_all_apps, buffer do
      [_, _, match] -> match
      [_, match] -> match
      nil -> nil
    end
  end

  def match_all_patterns(buffer) do
    case Regex.run(@match_all_apps1, buffer) do
      [_, _, _, key, match] -> {match, key}
      [_, key, match] -> {match, key}
      _other -> nil
    end
  end

  def app_module(app), do: Module.concat(MessageInput, app)
  def key_to_app_module(key), do: @app_lookup[key] |> app_module
  def key_to_app(key), do: @app_lookup[key]

  # defp app_pattern_match?(key, buffer) when key in @app_keys do
  #   run_pattern @pattern_key_lookup[key], buffer
  # end
  # defp app_pattern_match?(_, _), do: false

  def pattern_mod_match?(mod, buffer) do
    run_pattern @pattern_mod_lookup[mod], buffer
  end

  defp run_pattern(nil, _buffer), do: nil
  defp run_pattern(pattern, buffer) do
    # Logger.info "pattern: #{inspect pattern}, buffer: #{inspect buffer}"
    case Regex.run pattern, buffer do
      [_, _, match] -> match
      [_, match] -> match
      _other ->
        # Logger.error "other: #{inspect other}"
        nil
    end
  end

  def replace_word(buffer, replace, pos) do
    # IO.inspect {buffer, replace, pos}, label: "{buffer, replace, pos}"

    {start, finish} = String.split_at(buffer, pos)#   |> IO.inspect(label: "split at")
    if Regex.match? ~r/^[^\/].*\/.*$/, start do
      buffer
    else
      replace_head(start, replace) <> get_tail(finish)
    end
  end

  def get_tail(string) do
    case  Regex.run ~r/^[^\s]*(.*)$/, string do
      [_, rest] ->  rest
      nil -> ""
    end
  end
  def replace_head(string, replace) do
    String.replace string, ~r/(.*[#{@app_keys}])[^\s]*$/, "\\1#{replace}"
  end
end
