defmodule UcxUcc.Repo.Migrations.CreateSettingsFileUpload do
  use Ecto.Migration

  def change do
    create table(:settings_file_upload, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :file_uploads_enabled, :boolean, default: true
      add :maximum_file_upload_size_kb, :integer, default: 2000
      add :accepted_media_types, :string,
        default: "image/*,audio/*,video/*,application/zip,application" <>
        "/x-rar-compressed,application/pdf,text/plain,application/msword," <>
        "application/vnd.openxmlformats-officedocument.wordprocessingml." <>
        "document"
      add :protect_upload_files, :boolean, default: true
      add :storage_system, :string, default: "FileSystem"
      add :dm_file_uploads, :boolean, default: true
      add :s3_bucket_name, :string, default: ""
      add :s3_acl, :string, default: ""
      add :s3_aws_access_key_id, :string, default: ""
      add :s3_aws_secret_access_key, :string, default: ""
      add :s3_cdn_domain_for_downloads, :string, default: ""
      add :s3_region, :string, default: ""
      add :s3_bucket_url, :string, default: ""
      add :urls_expiration_timespan, :integer, default: 120
      add :system_path, :string, default: "/var/ucx_chat/uploads"
    end
  end
end
