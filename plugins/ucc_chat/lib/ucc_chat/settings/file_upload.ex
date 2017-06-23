defmodule UccSettings.Settings.Config.FileUpload do

  use UccSettings.Settings, scope: inspect(__MODULE__), repo: UcxUcc.Repo, schema: [
    [name: "file_uploads_enabled", type: "boolean", default: "true"],
    [name: "maximum_file_upload_size_kb", type: "integer", default: "2000"],
    [name: "storage_system", type: "string", default: "FileSystem"],
    [name: "accepted_media_types", type: "string", default: "image/*,audio/*,video/*,application/zip,application/x-rar-compressed,application/pdf,text/plain,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
    [name: "protect_upload_files", type: "boolean", default: "true"],
    [name: "dm_file_uploads", type: "boolean", default: "true"],
    [name: "s3_bucket_name", type: "string", default: ""],
    [name: "s3_acl", type: "string", default: ""],
    [name: "s3_aws_access_key_id", type: "string", default: ""],
    [name: "s3_aws_secret_access_key", type: "string", default: ""],
    [name: "s3_cdn_domain_for_downloads", type: "string", default: ""],
    [name: "s3_region", type: "string", default: ""],
    [name: "s3_bucket_url", type: "string", default: ""],
    [name: "urls_expiration_timespan", type: "integer", default: "120"],
    [name: "system_path", type: "string", default: "/var/ucx_chat/uploads"]]

end
