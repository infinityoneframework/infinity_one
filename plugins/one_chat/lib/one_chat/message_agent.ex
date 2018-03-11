defmodule OneChat.MessageAgent do
  @moduledoc """
  An Agent to handle fetching url previews in the background.
  """
  use GenServer

  alias InfinityOne.OnePubSub
  alias OneChat.Subscription

  require Logger

  @name __MODULE__
  # require Logger

  ############
  # Public API

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end

  def put_preview(_url, "" = html), do: html
  def put_preview(url, html) do
    GenServer.cast @name, {:put_preview, url, html}
    html
  end

  def get_preview(url) do
    GenServer.call @name, {:get_preview, url}
  end

  def get do
    GenServer.call @name, :get
  end

  ############
  # Callbacks

  @doc false
  def init(_) do
    Process.send_after self(), :initialize, 2_000
    {:ok, init_state()}
  end

  @doc false
  def handle_call({:get_preview, url}, _from, state) do
    {:reply, get_in(state, [:previews, url]), state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def handle_cast({:put_preview, url, html}, state) do
    {:noreply, put_in(state, [:previews, url], html)}
  end

  @doc false
  def handle_info(:initialize, state) do
    OnePubSub.subscribe "subscription:update", "*"
    {:noreply, state}
  end

  def handle_info({"subscription:update", "message:" <> action, payload}, state) do
    Subscription.update_message_action(action, payload)
    {:noreply, state}
  end


  #############
  # Private

  def init_state, do: %{previews: %{}}

  # def start_link do
  #   # Logger.warn "starting #{@name}"
  #   Agent.start_link(fn -> init_state() end, name: @name)
  # end

  # def init_state, do: %{previews: %{}}

  # def put_preview(_url, "" = html), do: html
  # def put_preview(url, html) do
  #   Agent.update @name, fn state ->
  #     put_in state, [:previews, url], html
  #   end
  #   html
  # end

  # def get_preview(url) do
  #   Agent.get @name, fn state ->
  #     get_in state, [:previews, url]
  #   end
  # end

  # def get do
  #   Agent.get @name, &(&1)
  # end

end
