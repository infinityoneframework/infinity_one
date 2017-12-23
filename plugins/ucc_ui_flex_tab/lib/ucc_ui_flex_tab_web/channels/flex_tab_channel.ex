defmodule UccUiFlexTab.FlexTabChannel do
  @moduledoc """
  Processes Rebel handlers for flex tab related events.

  The UccChatWeb.UiController processes a number of Rebel events. The
  flex tab related event handlers are delegated to this module.
  """
  use UccLogger

  import Rebel.Core, warn: false
  import Rebel.Query, warn: false

  alias UcxUcc.TabBar
  alias TabBar.Ftab
  alias UccUiFlexTabWeb.TabBarView

  @type socket :: Phoenix.Socket.t
  @type sender :: Map.t

  @doc false
  def do_join(socket, _event, _payload) do
    socket
  end

  @doc """
  Hander for tab button clicks.

  Handles toggling the tab window.
  """
  @spec flex_tab_click(socket, sender) :: socket
  def flex_tab_click(socket, sender) do
    Logger.debug "sender: #{inspect sender}"
    channel_id = get_channel_id(socket)
    user_id = socket.assigns.user_id
    Rebel.put_assigns socket, :channel_id, channel_id
    tab_id = sender["dataset"]["id"]
    tab = TabBar.get_button tab_id

    Ftab.toggle socket.assigns.user_id, channel_id, sender["dataset"]["id"],
      nil, fn
       :open, {_, args} ->
         apply(tab.module, :open, [socket, {user_id, channel_id, tab, sender}, args])
       :close, nil ->
         apply(tab.module, :close, [socket, sender])
     end
  end

  @spec flex_tab_open(socket, sender) :: socket
  def flex_tab_open(socket, sender) do
    Logger.debug "sender: #{inspect sender}"
    channel_id = get_channel_id(socket)
    user_id = socket.assigns.user_id
    Rebel.put_assigns socket, :channel_id, channel_id
    tab_id = sender["dataset"]["id"]
    tab = TabBar.get_button tab_id

    Ftab.open socket.assigns.user_id, channel_id, sender["dataset"]["id"],
      nil, fn
       :open, {_, args} -> apply(tab.module, :open, [socket, {user_id, channel_id, tab, sender}, args])
       :close, nil -> apply(tab.module, :close, [socket, sender])
     end
  end

  @doc """
  Redirect rebel calls to the configured module and function.

  This function is called for rebel-handler="flex_call". The element
  must have a data-id="tab_name" and a data-fun="function_name".

  This results in the function `function_name` called on the module
  defined in the button definition.
  """
  @spec flex_call(socket, sender) :: socket
  def flex_call(socket, sender) do
    tab = TabBar.get_button(sender["dataset"]["id"])
    fun = sender["dataset"]["fun"] |> String.to_atom()
    apply tab.module, fun, [socket, sender]
  end

  @doc """
  Callback when a new room is opened.

  Checks to see if a was previously open for the room. If so, the
  tab is reopened.
  """
  @spec room_join(String.t, Map.t, socket) :: socket
  def room_join(event, payload, socket) do
    trace event, payload

    # Logger.error "assigns" <> inspect(socket.assigns)
    user_id = socket.assigns.user_id
    channel_id = payload[:channel_id]

    # Theses should be here. Comment out now to make sure we don't create
    # a regression

    # socket = Phoenix.Socket.assign(socket, :channel_id, channel_id)
    # Rebel.put_assigns socket, :channel_id, channel_id

    Ftab.reload(user_id, channel_id, fn
      :open, {name, args} ->
        # Logger.error ":open #{inspect({name, args})}"
        tab = TabBar.get_button name
        apply tab.module, :open, [socket, {user_id, channel_id, tab, %{}}, args]
      :ok, nil ->
        with ocid when not is_nil(ocid) <- socket.assigns[:last_channel_id],
             {tab_name, _} <- UcxUcc.TabBar.get_ftab(user_id, ocid),
             %{module: mod} when is_atom(mod) <- TabBar.get_button(tab_name),
          do: apply(mod, :close, [socket, %{}])
    end)
  end

  @spec flex_close(socket, sender) :: socket
  def flex_close(socket, _sender) do
    execute socket, :click, on: ".tab-button.active"
  end

  @spec get_channel_id(socket) :: none | any
  defp get_channel_id(socket) do
    exec_js!(socket, "ucxchat.channel_id")
  end

  def refresh_tab_bar(socket, groups \\ ~w(channel)) do
    update socket, :replaceWith,
      set: Phoenix.View.render_to_string(TabBarView, "tab_bar.html", groups: groups),
      on: "#flex-tabs .flex-tab-bar"
  end
  # def room_update(_event, _payload, _socket) do

  # end
end
