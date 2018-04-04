defmodule OnePagesWeb.PageView do
  use OnePagesWeb, :view

  def home_intro do
    content_tag :p do
      [
        gettext("""
          InfinityOne combines the benefits of full-featured team chat with an
          extensible communications platform, built on a highly scalable, highly
          reliable platform.
          """),
        tag(:br),
        gettext("""
          Integrate InfinityOne with your phone system to instantly see who is
          on the phone, and call a user or any posted phone number with a simple click.
          """)
      ]
    end
  end
end
