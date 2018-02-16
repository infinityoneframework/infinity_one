defmodule UcxUccWeb.LandingView do
  use UcxUccWeb, :view

  def main_instructions do
    content_tag :p do
      ~g(It appears that this is the first time this application is being
         accessed after the initial installation. We need to configure a
         few things before its ready to be used in production.)
    end
  end

  def step1_instructions do
    [content_tag :p do
      [
        ~g(Enter the Domain Name of IP address of the server. This is used
           by the emailer to send links for things like registration, account
           confirmation and password reset links. i.e. "),
         content_tag :strong do
            "192.168.1.200"
         end,
         ~g(" or "),
         content_tag :strong do
           ~g("messaging.mycompany.com")
         end,
         "\"."
      ]
    end,
    content_tag :p do
      ~g(The host name you used to access this page is populated below. If this
         is the same host name that users will be using to accesss this application
         then you can leave this default. However, if you plan on accessing this site
         from a different IP address or host name, please enter it below.)
    end]
  end

  def step2_instructions do
    content_tag :p do
      ~g(Create an administrator account. This can be a your regular user
         account with the administrator role. This account will allow your
         to use the administration section of the application)
      end
  end

  def step3_instructions do
    [
      content_tag :p do
        ~g(Create the default channel. At least one channel is required and
           it cannot be removed. Furthermore, each new user will automatically
           subscribed to this channel.)
      end,
      content_tag :p do
        [
          ~g(The default name is ),
          content_tag :strong do
            ~g("general")
          end,
          ~g(. To accept the default, just click
             the next button. Otherwise, you can change the name if desired.)
        ]
      end
    ]
  end

  def step4_instructions do
    content_tag :p do
      ~g(You need to configure the name and email address to be used when the
         application sends a user invitation, registration, confimation, and
         password reset emails.)
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

end
