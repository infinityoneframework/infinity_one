defmodule UccUiFlexTab.FlexTabChannel do
  import Rebel.Core
  import Rebel.Query
  import Phoenix.Socket

  alias UccUiFlexTab.Flex
  alias UcxUcc.TabBar

  require Logger

  def do_join(socket, _event, _payload) do
    assign(socket, :flex, Flex.new())
  end

  def flex_tab_click(socket, sender) do
    channel_id = exec_js!(socket, "ucxchat.channel_id")
    socket
    |> assign(:channel_id, channel_id)
    |> toggle_flex(sender["dataset"]["id"], sender)
  end

  def flex_tab_item_click(socket, sender) do
    channel_id = exec_js!(socket, "ucxchat.channel_id")
    socket
    |> assign(:channel_id, channel_id)
    |> open_item_flex(sender["dataset"]["id"], sender)
  end

  def flex_call(socket, sender) do
    tab = TabBar.get_button(sender["dataset"]["id"])
    fun = sender["dataset"]["fun"] |> String.to_atom()
    apply tab.module, fun, [socket, sender]
  end

  defp toggle_flex(%{assigns: %{flex: fl} = assigns} = socket, tab, sender) do
    Flex.toggle(fl, socket, assigns[:channel_id], tab, sender)
  end

  defp open_item_flex(%{assigns: %{flex: fl} = assigns} = socket, tab, sender) do
    dataset = sender["dataset"]
    button = TabBar.get_button dataset["id"]
    key = dataset["key"]
    panel = %{"templ" => button.template, key => dataset[key]}
    Flex.open(fl, socket, assigns[:channel_id], tab, panel, sender)
  end

end
