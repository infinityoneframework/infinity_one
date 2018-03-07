defmodule UcxUccWeb.LandingView do
  use UcxUccWeb, :view

  def main_instructions do
    content_tag :p do
      gettext("""
        A few items require configuration for this new %{brand} installation. This one-time step
        configures the settings required to administer %{brand} and to start inviting users.
        """, brand: UcxUcc.brandname)
    end
  end

  def step1_instructions do
    [content_tag :p do
      [
        ~g(Enter the Domain Name or IP address of server. This name/address is used
           by emailer to send links for registration, account
           confirmation and password reset links. i.e. ),
         content_tag :strong do
           ~g("192.168.1.200")
         end,
         ~g( or ),
         content_tag :strong do
           ~g("messaging.mycompany.com".)
         end
      ]
    end,
    content_tag :p do
      ~g(The host name used to access this page is displayed below. The default can
          be used if it is the name/address for production service.
          However, if the plan is to use another address, e.g. external host name,
          please enter it below.)
    end]
  end

  def step2_instructions do
    content_tag :p do
      gettext("""
        Create an administrator account. This can be a regular user account with administrator role.
        This account will allow the use of administration section of %{brand}.
        """, brand: UcxUcc.brandname)
    end
  end

  def step3_instructions do
    [
      content_tag :p do
        ~g(Create the default channel. At least one channel is required and
           it cannot be removed. Furthermore, each new user will automatically
           be subscribed to this channel. Additional default channels can be configured later.)
      end,
      content_tag :p do
        [
          ~g(The default name is ),
          content_tag :strong do
            ~g("general")
          end,
          ~g(. To accept the default name, click
             the next button, or edit and change the channel name.)
        ]
      end
    ]
  end

  def step4_instructions do
    content_tag :p do
      gettext("""
        Configure the name and email address to be used when %{brand} sends a user, invitation,
        registration, confirmation, and password reset emails.
        """, brand: UcxUcc.brandname)
    end
  end

  def summary_fields(fields) do
    [
      {:title, ~g"Site URL / Host Name", ""},
      {:field, ~g"Host Name", fields["host_name"]},
      {:title, ~g"Admin User", ""},
      {:field, ~g"Name", fields["admin"]["name"]},
      {:field, ~g"Username", fields["admin"]["username"]},
      {:field, ~g"Email", fields["admin"]["email"]},
      {:title, ~g"Default Channel", ""},
      {:field, ~g"Name", fields["default_channel"]["name"]},
      {:title, ~g"Send Email Settings", ""},
      {:field, ~g"From Name", fields["email_from"]["name"]},
      {:field, ~g"From Email Address", fields["email_from"]["email"]}
    ]
  end
  def next_button(tab_index) do
    render "next_button.html", tab_inx: tab_index
  end

  def prev_button(tab_index) do
    render "prev_button.html", tab_inx: tab_index
  end

  def summary_button(tab_index) do
    render "summary_button.html", tab_inx: tab_index
  end

  def host(conn), do: Map.get(conn, :host, "")

  def step1, do: ~g(Site URL / Host Name)
  def step2, do: ~g(Administrator Account)
  def step3, do: ~g(Default Channel)
  def step4, do: ~g(Sending Email Settings)
  def step5, do: ~g(Summary of Your Input)
  def step6, do: ~g(Complete)

  # helper functions

  def restart_message do
    [
      ~g(Login with your administrator account, open Administration section, and select the ),
      content_tag(:strong, do: ~g(General)),
      ~g( menu. Click on the ),
      content_tag(:strong, do: ~g(RESTART THE SERVER)),
      ~g( button. The application restart takes approximately one minute to complete.
        After restart, login as administrator and invite users as described below.)
    ]
  end
end
