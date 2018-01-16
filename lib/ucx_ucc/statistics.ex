defmodule UcxUcc.Statistics do
  use GenServer

  require Logger

  @name :stats

  def start_link(opts \\ %{}) do
    GenServer.start_link __MODULE__, [opts], name: @name
  end

  def stop, do: GenServer.stop(@name)
  def get, do: GenServer.call(@name, :get)
  def get(key), do: GenServer.call(@name, {:get, key})

  def init([opts]) do
    GenServer.cast self(), :collect

    {:ok, %{
      interval: opts[:interval] || 30_000,
      buffer_size: opts[:buffer_size] || (8 * 60 * 5),
      history_size: opts[:hisory_size] || 100,
      buffer: [],
      history: [],
    }}
  end

  def handle_cast(:collect, state) do
    {:noreply, add_collection(get_all(), state)}
  end

  def handle_info(:collect, state) do
    {:noreply, add_collection(get_all(), state)}
  end

  def handle_call(:get, _, state) do
    {:reply, state, state}
  end

  def start_timer(state) do
    Process.send_after self(), :collect, state.interval
    state
  end

  def add_collection(item, %{butter: []} = state) do
    state
    |> add_to_history(item)
    |> add_to_buffer(item)
    |> start_timer()
  end

  def add_collection(item, %{} = state) do
    state
    |> add_to_buffer(item)
    |> start_timer
  end

  def add_to_history(%{history: []} = state, item) do
    Map.put state, :history, [item]
  end
  def add_to_history(%{} = state, item) do
    update_in state, [:history], fn history ->
      history =
        if length(history) > state.history_size,
          do: List.pop_at(history, -1) |> elem(1), else: history
      [item | history]
    end
  end

  def add_to_buffer(%{buffer: []} = state, item) do
    Map.put state, :buffer, [item]
  end
  def add_to_buffer(%{buffer: buffer} = state, item) do
    if length(buffer) > state.buffer_size do
      {last, buffer} = List.pop_at(buffer, -1)
      state
      |> Map.put(:buffer, [item | buffer])
      |> add_to_history(last)
    else
      Map.put state, :buffer, [item | buffer]
    end
  end

  def get_all do
    get_basic()
    |> Map.merge(get_memory())
    |> Map.merge(get_extra())
  end

  def print_all do
    Enum.each(get_all(), &print_line(&1, ""))
  end

  def print_line(item, leader \\ "")
  def print_line({k, v}, leader) when is_binary(v) or is_number(v) do
    IO.puts leader <> "#{k}: #{v}"
  end
  def print_line({k, v}, leader) when is_list(v) do
    IO.puts leader <> "#{k}"
    Enum.each v, &print_line(&1, leader <> "  ")
  end
  def print_line({k, v}, leader) do
    IO.puts leader <> "#{k}: #{inspect v}"
  end

  def get_basic do
    {{:input, input}, {:output, output}} = statistics(:io)
    {context_switches, 0} = statistics(:context_switches)
    dt = NaiveDateTime.utc_now()

    %{
      dt: dt,
      dt_string: to_string(dt),
      input_io: input,
      output_io: output,
      context_switches: context_switches,
      running_queue: statistics(:run_queue),
      kernel_pool: system_info(:kernel_poll),
      process_count: system_info(:process_count),
      process_limit: system_info(:process_limit),
      nodes: :erlang.nodes() |> length |> Kernel.+(1),
      ports: :code.all_loaded() |> length,
    }
  end

  def get_memory do
    %{
      memory_usage: :erlang.memory |> Enum.map(fn {k, v} -> {k, Float.round(v / 1024 / 1024, 2)} end),
      garbage_collections: statistics(:garbage_collection) |> elem(0),
    }
  end

  def get_extra do
    %{
      check_io: system_info(:check_io),
      cpu_topology: system_info(:cpu_topology),
      atom_limit: system_info(:atom_limit),
      atom_count: system_info(:atom_count),
    }
  end

  def get_info do
    :info
    |> system_info
    |> String.split("\n", trim: true)
    |> Enum.reduce({nil, nil, %{}}, fn
      "=" <> name, {nil, nil, acc} ->
        {name, %{}, acc}
      "=" <> name, {topic, map, acc} ->
        acc = Map.put acc, topic, map
        {name, %{}, acc}
      item, {topic, map, acc} ->
        map =
          case String.split(item, ":", parts: 2) do
            [name, value] ->
              Map.put map, name, value
            [one] ->
              Map.put map, one, nil
          end
        {topic, map, acc}
    end)
    |> add_last
  end

  defp add_last({topic, map, acc}), do: Map.put(acc, topic, map)

  def get_info(key), do: Map.get(get_info(), key)
  def get_info(%{} = data, key), do: Map.get(data, key)
  def get_info(key, value), do: get_info() |> get_info(key, value)
  def get_info(%{} = data, key, value) do
    case Map.get data, key do
      %{} = map ->
        map[value]
      _ -> {:error, :invalid_key}
    end
  end

  def get_info_keys, do: get_info() |> get_info_keys()
  def get_info_keys(%{} = data), do: data |> Map.keys()
  def get_info_keys(key), do: get_info(key) |> Map.keys()

  def statistics(item), do: :erlang.statistics(item)
  def system_info(item), do: :erlang.system_info(item)

  def report(key, field \\ nil)
  def report(:memory_usage, nil), do: report(:memory_usage, :total)
  def report(:memory_usage, field) do
    data = get()
    buffer = Enum.reverse data.buffer
    history = Enum.reverse data.history
    all = history ++ buffer
    {first, last} = {hd(all), List.last(all)}
    {first, last} = {get_in(first, [:memory_usage, field]), get_in(last, [:memory_usage, field])}
    {first, last, last - first}
  end

end
