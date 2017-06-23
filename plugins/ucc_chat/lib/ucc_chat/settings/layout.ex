defmodule UccSettings.Settings.Config.Layout do

  use UccSettings.Settings, scope: inspect(__MODULE__), repo: UcxUcc.Repo, schema: [
    [name: "display_roles", type: "boolean", default: "true"],
    [name: "merge_private_groups", type: "boolean", default: "true"],
    [name: "user_full_initials_for_avatars", type: "boolean", default: "false"],
    [name: "body_font_family", type: "string", default: "-apple-system, BlinkMacSystemFont, Roboto, 'Helvetica Neue', Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Meiryo UI'"],
    [name: "content_home_title", type: "string", default: "Home"],
    [name: "content_home_body", type: "string", default: "Welcome to Ucx Chat <br> Go to APP SETTINGS -> Layout to customize this intro."],
    [name: "content_side_nav_footer", type: "string", default: ~s(<img src="/images/logo.png" />)]]
end
