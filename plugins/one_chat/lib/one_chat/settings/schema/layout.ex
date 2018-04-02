defmodule OneChat.Settings.Schema.Layout do
  use OneSettings.Settings.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @content_home_body_default """
    # Welcome to InfinityOne

    InfinityOne is your one-stop location of all your communication needs.

    Click on one of the Rooms listed on the left navigation panel to get started.

    Access InfinityOne in your browser, or download [The Desktop App](/apps) for an even better experience!

    ## Helpful Links

    * [Desktop Apps](/apps)
    * [InfinityOne Overview](/pages)
    * [Features](/features)
    """

  schema "settings_layout" do
    field :display_roles, :boolean, default: true
    field :merge_private_groups, :boolean, default: true
    field :user_full_initials_for_avatars, :boolean, default: false
    field :body_font_family, :string,
      default: "-apple-system, BlinkMacSystemFont, Roboto, 'Helvetica Neue'" <>
      ", Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI', " <>
      "'Segoe UI Emoji', 'Segoe UI Symbol', 'Meiryo UI'"
    field :content_home_title, :string, default: "Home"
    field :content_home_body, :string,
      default: @content_home_body_default
    field :content_side_nav_footer, :string,
      default: ~s(<img src="/images/logo.png" />)
  end

  @fields [
    :display_roles,
    :merge_private_groups,
    :user_full_initials_for_avatars,
    :body_font_family,
    :content_home_title,
    :content_home_body,
    :content_side_nav_footer,
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def content_home_body_default, do: @content_home_body_default
end
