defmodule UccUiFlexTab.Web.TabBarView do
  use UccUiFlexTab.Web, :view

  alias UcxUcc.TabBar

  def visible?(tab, group) do
    group in Map.get(tab, :groups, [])
  end

  def buttons do
    TabBar.get_buttons
  end

  def open? do

  end

  def get_open_ftab(nil, _), do: nil
  def get_open_ftab({title, _}, flex_tabs) do
    Enum.find(flex_tabs, fn tab ->
      tab[:open] && tab[:title] == title
    end)
  end

  def cc(config, item) do
    if apply UccSettings, item, [config] do
      ""
    else
      " hidden"
    end
  end

  def uu(true, "User Info"), do: ""
  def uu(false, "Members List"), do: ""
  def uu(_, _), do: " hidden"

  def get_flex_tabs(chatd, open_tab) do
    user = chatd.user
    user_mode = chatd.channel.type == 2
    switch_user =
      if Application.get_env(:ucx_chat, :switch_user, false)
        and UcxUcc.env() != :prod do
        ""
      else
        " hidden"
      end

    config = UccSettings.get_all()
    defn = UccChat.FlexBarService.default_settings()
    tab =
      case open_tab do
        {title, _} -> %{title => true}
        _ -> %{}
      end
    [
      {"IM Mode", "icon-chat", ""},
      {"Rooms Mode", "icon-hash", " hidden"},
      {"Info", "icon-info-circled", ""},
      {"Search", "icon-search", ""},
      {"User Info", "icon-user", uu(user_mode, "User Info")},
      {"Members List", "icon-users", uu(user_mode, "Members List")},
      {"Notifications", "icon-bell-alt", ""},
      {"Files List", "icon-attach", ""},
      {"Mentions", "icon-at", ""},
      {"Stared Messages", "icon-star", cc(config, :allow_message_staring)},
      {"Knowledge Base", "icon-lightbulb", " hidden"},
      {"Pinned Messages", "icon-pin", cc(config, :allow_message_pinning)},
      {"Past Chats", "icon-chat", " hidden"},
      {"OTR", "icon-key", " hidden"},
      {"Video Chat", "icon-videocam", " hidden"},
      {"Snippeted Messages", "icon-code", cc(config, :allow_message_snippeting)},
      {"Switch User", "icon-login", switch_user},
      {"Logout", "icon-logout", " hidden"},
    ]
    |> Enum.map(fn {title, icon, display} ->
      if tab[title] do
        titlea = String.to_atom title
        %{
          title: title,
          icon: icon,
          display: display,
          open: true,
          templ: defn[titlea][:templ]
        }
      else
        display = check_im_mode_display(title, user.account.chat_mode, display)
        %{
          title: title,
          icon: icon,
          display: display
        }
      end
    end)
  end

  defp check_im_mode_display("IM Mode", true, _), do: " hidden"
  defp check_im_mode_display("IM Mode", _, _), do: ""
  defp check_im_mode_display("Rooms Mode", false, _), do: " hidden"
  defp check_im_mode_display("Rooms Mode", _, _), do: ""
  defp check_im_mode_display("Members List", true, _), do: " hidden"
  defp check_im_mode_display("Pinned Messages", true, _), do: " hidden"
  defp check_im_mode_display("Info", true, _), do: " hidden"
  defp check_im_mode_display(_, _, display), do: display
end
