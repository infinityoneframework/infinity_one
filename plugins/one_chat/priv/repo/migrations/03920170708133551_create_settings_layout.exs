defmodule InfinityOne.Repo.Migrations.CreateSettingsLayout do
  use Ecto.Migration

  def change do
    create table(:settings_layout, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_roles, :boolean, default: true
      add :merge_private_groups, :boolean, default: true
      add :user_full_initials_for_avatars, :boolean, default: false
      add :body_font_family, :string,
        default: "-apple-system, BlinkMacSystemFont, Roboto, 'Helvetica " <>
        "Neue', Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI', " <>
        "'Segoe UI Emoji', 'Segoe UI Symbol', 'Meiryo UI'"
      add :content_home_title, :string, default: "Home"
      add :content_home_body, :string,
        default: "Welcome to Ucx Chat <br> Go to APP SETTINGS -> Layout" <>
        " to customize this intro."
      add :content_side_nav_footer, :string,
        default: ~s(<img src="/images/logo.png" />)
    end
  end
end
