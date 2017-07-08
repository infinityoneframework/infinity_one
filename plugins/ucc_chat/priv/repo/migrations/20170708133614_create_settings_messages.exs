defmodule UcxUcc.Repo.Migrations.CreateSettingsMessages do
  use Ecto.Migration

  def change do
    create table(:settings_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :allow_message_editing, :boolean, default: true
      add :block_message_editing_after, :integer, default: 0
      add :block_message_deleting_after, :integer, default: 0
      add :allow_message_deleting, :boolean, default: true
      add :show_edited_status, :boolean, default: true
      add :show_deleted_status, :boolean, default: false
      add :allow_bad_words_filtering, :boolean, default: false
      add :add_bad_words_to_blacklist, :string, default: ""
      add :max_channel_size_for_all_message, :integer, default: 0
      add :max_allowed_message_size, :integer, default: 5000
      add :show_formatting_tips, :boolean, default: true
      add :grouping_period_seconds, :integer, default: 300
      add :embed_link_previews, :boolean, default: true
      add :disable_embedded_for_users, :string, default: ""
      add :embeded_ignore_hosts, :string, default:
        "localhost, 127.0.0.1, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16"
      add :time_format, :string, default: "LT"
      add :date_format, :string, default: "LL"
      add :hide_user_join, :boolean, default: false
      add :hide_user_leave, :boolean, default: false
      add :hide_user_removed, :boolean, default: false
      add :hide_user_added, :boolean, default: false
      add :hide_user_muted, :boolean, default: false
      add :allow_message_pinning, :boolean, default: true
      add :allow_message_staring, :boolean, default: true
      add :allow_message_snippeting, :boolean, default: false
      add :autolinker_strip_prefix, :boolean, default: false
      add :autolinker_scheme_urls, :boolean, default: true
      add :autolinker_www_urls, :boolean, default: true
      add :autolinker_tld_urls, :boolean, default: true
      add :autolinker_url_regexl, :string, default: "(://|www\.).+"
      add :autolinker_email, :boolean, default: true
      add :autolinker_phone, :boolean, default: true
    end

  end
end
