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
    Logger.warn "flex_tab_click id #{sender["dataset"]["id"]}, #{inspect channel_id}, assigns: #{inspect socket.assigns}"
    Logger.warn inspect(sender, label: "Sender")
    socket
    |> assign(:channel_id, channel_id)
    |> toggle_flex(sender["dataset"]["id"], sender)
  end

  def flex_call(socket, sender) do
    Logger.error "......... sender: #{inspect sender}"
    tab = TabBar.get_button(sender["dataset"]["id"])
    fun = sender["dataset"]["fun"] |> String.to_atom()
    apply tab.module, fun, [socket, sender]
    # channel_id = exec_js!(socket, "ucxchat.channel_id")
    # FlexBarService.handle_in sender["dataset"]["id"], %{"channel_id" => channel_id}, socket
  end

  defp toggle_flex(%{assigns: %{flex: fl} = assigns} = socket, tab, params) do
    # assign(socket, :flex, Flex.toggle(fl, assigns[:channel_id], tab, params))
    Flex.toggle(fl, socket, assigns[:channel_id], tab, params)
    |> IO.inspect(label: "toggle_flex socket")
  end

end
