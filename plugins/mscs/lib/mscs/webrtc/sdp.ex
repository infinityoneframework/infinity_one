defmodule Mscs.WebRtc.Sdp do
  @moduledoc """
  Handle SDP message parsing, extraction, and rendering back into text.

  ## Usage

  The example below parses a text SDP message, generating an SDP struct
  then renders it back into the text message. In this example, the output
  should be the same as the input.

      Mscs.WebRtc.Sdp.parse(sdp_message)
      |> Mscs.WebRtc.Sdp.render

  """
  require Logger
  import Kernel, except: [to_string: 1]

  @order [:v, :o, :s, :c, :t, :m, :a]

  defstruct v: "", o: "", s: "", t: "", c: [], m: [], a: [], error: [],
            order: []

  def new, do: %__MODULE__{}
  def new(opts), do: struct(new, opts)

  @doc """
  Parse a text SDP message.

  Generates a SDP struct from a text SDP message to easily fetch
  specific fields, or to update the message before rendering it
  back into the text message.
  """
  def parse(sdp) do
    lines = String.split(sdp, "\r\n", trim: true)
    # Logger.warn "lines: #{inspect lines}"
    new_sdp = Enum.reduce(lines, __MODULE__.new, fn(line, acc) ->
      case line do
        "v=" <> rest -> add_field(acc, :v, rest)
        "o=" <> rest -> add_field(acc, :o, rest)
        "s=" <> rest -> add_field(acc, :s, rest)
        "t=" <> rest -> add_field(acc, :t, rest)
        "c=IN IP4 " <> rest -> add_field(acc, :c, rest)
        "m=" <> rest -> add_field(acc, :m, rest)
        "a=" <> rest -> add_field(acc, :a, rest)
        other ->
          Logger.error "Parse error '#{other}'"
          struct(acc, error: acc.error ++ [other])
          |> add_order_entry(:error)
      end
    end)
    struct(new_sdp, order: new_sdp.order)
  end

  def add_field(sdp, key, data) when key in [:v, :o, :s],
    do: set_single_field(sdp, key, data)
  def add_field(sdp, :t, data), do: set_single_field(sdp, :t, handle_t(data))
  def add_field(sdp, :a, data), do: handle_a(sdp, data)
  def add_field(sdp, :c, data) do
    struct(sdp, c: sdp.c ++ [[nettype: :IN, addrtype: :IP4, addr: data]])
    |> add_order_entry(:c)
  end
  def add_field(sdp, :m, data) do
    struct(sdp, m: handle_m(sdp.m, data))
    |> add_order_entry(:m)
  end

  def delete_field(sdp, key, field \\ nil) do
    # IO.puts "sdp: #{inspect sdp}"
    items = case Map.get(sdp, key, []) do
      nil -> nil
      other when is_list(other) -> Keyword.delete(other, field)
      _ -> ""
    end

    order = sdp.order
    |> Enum.filter(fn(o) ->
      case o do
        {^key, {^field, _}} -> false
        ^key -> false
        _ -> true
      end
    end)
    Map.put(sdp, key, items)
    |> Map.put(:order, order)
  end

  def replace_field(sdp, key, data) when is_binary(data) do
    # IO.puts "replace_field sdp: #{inspect sdp}"
    [field, value] = String.split(data, ":", parts: 2)
    field = String.to_atom(field)
    _result = if has_field?(sdp, key, field) do
      updated = case Map.get(sdp, key) do
        list when is_list(list) ->
          Enum.map(list, fn({k, v}) ->
            if k == field, do: {k, [value]}, else: {k, v}
          end)
        _ -> value
      end
      Map.put(sdp, key, updated)
    else
      add_field(sdp, key, data)
    end
    # IO.puts "result: #{inspect result}"
    # _result
  end

  def has_field?(sdp, key, field \\ nil) when is_atom(field) do
    case Map.get(sdp, key) do
      nil -> false
      [] -> false
      list when is_list(list) -> Keyword.get(list, field, false)
      "" -> false
      _other -> true
    end
  end

  defp handle_a(acc, string) do
    try do
      fields = String.split(string, ":", parts: 2)
      # Logger.warn "-> #{inspect hd(fields)}"
      struct(acc, a: _handle_a(acc.a, fields))
      |> add_order_entry(:a, hd(fields))
    rescue
      e in ArgumentError ->
        Logger.warn "Error parsing a=#{string}, " <> e.message
        acc
    end
  end
  defp _handle_a(list, ["rtpmap", rest]) do
    [payload_type, encoding] = String.split(rest, " ")
    [encoding_name, clock_rate | params] = String.split(encoding, "/")
    params = if params == [], do: [], else: [params: params]
    rtpmap = {String.to_integer(payload_type), [encoding_name: encoding_name, clock_rate: clock_rate] ++ params}
    case list[:rtpmap] do
      nil -> list ++ [{:rtpmap, [rtpmap]}]
      other -> Keyword.put(list, :rtpmap, other ++ [rtpmap])
    end
  end
  defp _handle_a(list, ["fmtp", rest]) do
    # Logger.warn "fmtp: #{inspect rest}"
    [payload_type, value] = String.split(rest, " ", parts: 2)
    fmtp = {String.to_integer(payload_type), value}
    case list[:fmtp] do
      nil   -> list ++ [{:fmtp, [fmtp]}]
      other -> Keyword.put(list, :fmtp, other ++ [fmtp])
    end
  end
  defp _handle_a(list, ["candidate", rest]) do
    # Logger.warn "handle candate list: #{inspect list}"
    [foundation, component_id, transport, priority, address, port, "typ", type | extended] =
    String.split(rest, " ")
    custom = unless rem(Enum.count(extended), 2) == 0 do
      Logger.warn "Ingnoring extended. Must be multiple of 2"
      []
    else
      case Enum.chunk(extended, 2) |> Enum.map(fn([k,v]) -> {String.to_atom(k), v} end) do
        [] -> []
        cust -> [custom: cust]
      end
    end
    candidate = [
      foundation: foundation, component_id: String.to_integer(component_id),
      transport: String.to_atom(transport), priority: String.to_integer(priority),
      address: address, port: String.to_integer(port), type: String.to_atom(type)
    ] ++ custom
    case list[:candidate] do
      nil   -> list ++ [{:candidate, [candidate]}]
      other -> Keyword.put(list, :candidate, other ++ [candidate])
    end
  end

  defp _handle_a(list, [other, rest]) do
    field = String.to_atom(other)
    case list[field] do
      nil ->
        list ++ [{field, [rest]}]
      lst when is_list(lst) ->
        Keyword.put(list, field, lst ++ [rest])
    end
  end
  defp _handle_a(list, [other]), do: list ++ [{String.to_atom(other), true}]
  defp _handle_a(list, other) do
    Logger.warn "Invalid a=#{inspect other}"
    list
  end

  defp handle_m(list, string) do
    try do
      [media, port, proto | fmt] = String.split(string)
      media = if media in ~w(audio video text application message),
        do: String.to_atom(media),
        else: raise(ArgumentError, message: "Invalid media type '#{media}'")
      {port, num_ports} = case String.split(port, "/") do
        [port, num_ports] -> {String.to_integer(port), String.to_integer(num_ports)}
        [port]            -> {String.to_integer(port), 1}
        _                 -> raise(ArgumentError, message: "Invalid port description '#{port}'")
      end
      fmt_list = Enum.map(fmt, &(String.to_integer(&1)))
      list ++ [[media: media, port: port, num_port: num_ports, proto: proto, fmt: fmt_list]]
    rescue
      e in ArgumentError ->
        Logger.warn "Error parsing m=#{string}, " <> e.message
        list
    end
  end

  defp handle_t(string) do
    case String.split(string, " ") do
      [start, stop] ->
        [start_time: parse_int(start), stop_time: parse_int(stop)]
      _ ->
        Logger.warn "Could not parse t #{string}"
        []
    end
  end

  defp set_single_field(sdp, field, value) do
    if Map.get(sdp, field) == "" do
      Map.put(sdp, field, value)
      |> add_order_entry(field)
    else
      Logger.warn "SDP duplicate field #{field}"
      sdp
      |> add_order_entry(nil)
    end
  end

  defp add_order_entry(sdp, entry) when entry in [:c, :m, :a, :error] do
    count = Enum.count(Map.get(sdp, entry))
    struct(sdp, order: [{entry, count - 1} | sdp.order])
  end
  defp add_order_entry(sdp, entry) do
    struct(sdp, order: [entry | sdp.order])
  end
  defp add_order_entry(sdp, :a, field) do
    field = String.to_atom field
    item = case Keyword.get(sdp.a, field) do
      list when is_list(list) ->
        {:a, {field, Enum.count(list) - 1}}
      _ ->
        {:a, field}
    end
    struct(sdp, order: [item | sdp.order])
  end

  def count(list) when is_list(list) do
    Enum.count list
  end
  def count(_), do: 0

  defp parse_int(string) do
    case Integer.parse string do
      {int, ""} -> int
      _         ->
        Logger.warn "Could not parse integer '#{string}'"
        0
    end
  end

  @doc """
  Render a parsed SDP message.

  Generates the string representation of a parsed SDP message.
  """
  def render(%__MODULE__{} = sdp) do
    result =
    Enum.reverse(sdp.order)
    |> Enum.reduce([], &([render_entry(sdp, &1) | &2]))
    |> List.flatten
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.reverse
    |> Enum.join("\r\n")
    result <> "\r\n"
  end

  def render_field(sdp, key, field) do
    Map.get(sdp, key, [])
    |> Keyword.get(field, [])
    |> Enum.map(fn(item) ->
      do_line(sdp, key, field, item) |> String.slice(2, 5000)
    end)
  end

  defp render_entry(sdp, {key, {field, index}}) do
    case Map.get(sdp, key, []) |> Keyword.get(field, []) |> Enum.at(index) do
      nil -> nil
      item -> do_line(sdp, key, field, item)
    end
  end
  defp render_entry(sdp, {key, index}) when is_integer(index) do
    case Map.get(sdp, key, []) |> Enum.at(index) do
      nil -> nil
      item -> do_line(sdp, key, item)
    end
  end
  defp render_entry(sdp, {key, field}) when is_atom(field) do
    case Map.get(sdp, key, []) |> Keyword.get(field) do
      nil -> nil
      item -> do_line(sdp, key, field, item)
    end
  end
  defp render_entry(sdp, key) do
    case Map.get sdp, key do
      "" -> nil
      [] -> nil
      value -> do_line(sdp, key, value)
    end
  end

  defp do_line(sdp, key, [[_ | _] | _] = list) do
    Enum.map list, &(do_line sdp, key, &1)
  end

  defp do_line(sdp, :a, [_|_] = list) do
    Enum.map(list, fn({field, data}) ->
      do_line(sdp, :a, field, data)
    end)
    |> Enum.reverse
  end
  defp do_line(sdp, key, list) when is_list(list) do
    list = if key == :m do
      num_port = list[:num_port]
      if num_port > 1 do
        Keyword.put list, :port, to_string(list[:port]) <> "/" <> to_string(num_port)
      else
        list
      end
      |> Keyword.delete(:num_port)
    else
      list
    end
    value =
      Keyword.values(list)
      |> Enum.map(&(to_string &1))
      |> Enum.join(" ")
    do_line sdp, key, value
  end
  defp do_line(_sdp, key, value) do
    Atom.to_string(key) <> "=" <> to_string(value)
  end
  defp do_line(sdp, key, value, true) do
    do_line(sdp, key, value)
  end

  defp do_line(sdp, key, :candidate, [_|_] = list) when list != [] do
    {first,[type | extra]} =
      list
      |> Keyword.values
      |> Enum.split(6)
    values = first ++ ["typ", type]
    str = case extra do
      [lst] ->
        res = Enum.reduce(lst, [], fn({k,v}, acc) ->
          [to_string(v), to_string(k) | acc]
        end)
        |> Enum.reverse
        values ++ res
      _ -> values
    end
    |> Enum.join(" ")
    do_line sdp, key, :candidate, str
  end
  defp do_line(sdp, key, field, data) when is_list(data) do
    Enum.map(data, &(do_line sdp, key, field, &1))
    |> Enum.reverse
  end
  defp do_line(sdp, key, :rtpmap, {id, list}) do
    rtpmap = do_line sdp, key, "rtpmap", id, list
    case Keyword.get(sdp.a, :fmtp, []) |> List.keyfind(id, 0) do
      nil -> rtpmap
      {_, data} ->
        [do_line(sdp, key, "fmtp", id, data), rtpmap]
    end
  end
  defp do_line(_sdp, _key, :fmtp, _data), do: nil
  defp do_line(sdp, key, value, data) do
    do_line(sdp, key, to_string(value) <> ":" <> to_string(data))
  end
  defp do_line(sdp, key, field, id, list) when is_list(list) do
    do_line sdp, key, field, id, Keyword.values(list) |> Enum.join("/")
  end
  defp do_line(sdp, key, field, id, data) do
    do_line sdp, key, to_string(field) <> ":" <> to_string(id) <> " " <> data
  end

  defp to_string(value) when is_binary(value), do: value
  defp to_string(value) when is_atom(value), do: Atom.to_string(value)
  defp to_string(value) when is_integer(value), do: Integer.to_string(value)
  defp to_string(value) when is_list(value),
    do: Enum.map(value, &(to_string &1)) |> Enum.join(" ")

end
