defmodule UccChat.Settings.FileUpload do
  use UccSettings.Settings, schema: UccChat.Settings.Schema.FileUpload
  alias UccChat.Settings.Schema.FileUpload

  @usage_re ~r/^(?:[^\s]+\s+\d+\s+)(\d+)(?:\s+)(\d+)/

  @doc """
  Check that non of the enabled file uploads quotas have been crossed.
  """
  def quota_check_success? do
    quota_check_success? get()
  end

  def quota_check_success?(%FileUpload{} = settings) do
    quota_check_success? settings, []
  end

  def quota_check_success?(opts) when is_list(opts) do
    quota_check_success? get(), opts
  end

  def quota_check_success?(%FileUpload{} = settings, opts) do
    disk_quota_size_success?(settings, opts) and
      disk_quota_percent_success?(settings, opts) and
      disk_quota_remaining_success?(settings, opts)
  end

  @doc """
  Check that the size of uploads folder is less than the quota.
  """

  def disk_quota_size_success?(%FileUpload{} = settings, opts) do
    file_size_kb = opts[:file_size_kb] || 0
    with true <- settings.disk_quota_size_enabled,
         {:ok, size} <- get_uploads_size(settings),
         size <- size + (file_size_kb * 1024) do

      if size > settings.disk_quota_size_mb, do: false, else: true
    else
      _ -> true
    end
  end

  def disk_quota_size_success?(opts) when is_list(opts) do
    disk_quota_size_success? get(), opts
  end

  def disk_quota_size_success?(%FileUpload{} = settings) do
    disk_quota_size_success? settings, []
  end

  @doc """
  Check that the percent of used disk space is less than the quota.
  """
  def disk_quota_percent_success?(%FileUpload{} = settings, opts) do
    if settings.disk_quota_percent_enabled do
      case get_disk_usage(settings, opts) do
        {:ok, %{percent: percent}} ->
          percent <= settings.disk_quota_percent
        _error ->
          true
      end
    else
      true
    end
  end

  def disk_quota_percent_success?(opts) when is_list(opts) do
    disk_quota_percent_success? get(), opts
  end

  def disk_quota_percent_success?(%FileUpload{} = settings) do
    disk_quota_percent_success? settings, []
  end

  @doc """
  Check that the amount of available space is greater than the quota.

  Verifies that the quota has not been exceeded if the setting is enabled.
  """
  def disk_quota_remaining_success?(%FileUpload{} = settings, opts) do
    {file_size_kb, opts} = Keyword.pop(opts, :file_size_kb, 0)

    if settings.disk_quota_remaining_enabled do
      case get_disk_usage(settings, opts) do
        {:ok, %{available: available}} ->
          (available - file_size_kb) >= settings.disk_quota_remaining_mb * 1024
        _error ->
          true
      end
    else
      true
    end
  end

  def disk_quota_remaining_success?(opts) when is_list(opts) do
    disk_quota_remaining_success? get(), opts
  end

  def disk_quota_remaining_success?(%FileUpload{} = settings) do
    disk_quota_remaining_success? settings, []
  end

  @doc """
  Retrieve the size of the configured uploads folder.
  """
  def get_uploads_size do
    get_uploads_size get()
  end

  @doc """
  Get the size of the uploads folder
  """
  def get_uploads_size(settings) do
    with {results, 0} <- System.cmd("du", ["-s", settings.system_path]),
         [_, size_str] <- Regex.run(~r/(\d+)/, results),
         {size, ""} <- Integer.parse(size_str) do
      {:ok, size / 1024}
    else
      {_, errno} -> {:error, errno}
      _ ->          {:error, :invalid_results}
    end
  end

  @doc """
  Get partition usage information.

  Returns used, available and percent values in KB, adjusted by an
  optional file size (defaults to 0).
  """
  def get_disk_usage(settings, opts) do
    path = opts[:path] || settings.system_path
    file_size_kb = opts[:file_size_kb] || 0

    with {results, 0} <- System.cmd("df", ["-P", path]),
         [_, entry] <- String.split(results, "\n", trim: true),
         [_, used_str, available_str] <- Regex.run(@usage_re, entry),
         {used, ""} <- Integer.parse(used_str),
         {available, ""} <- Integer.parse(available_str) do

      used = used + file_size_kb
      available = available - file_size_kb

      {:ok, %{
        used: used,
        available: available,
        percent: used / (used + available) * 100
      }}
    else
      error -> {:error, error}
    end
  end

  def get_disk_usage(%{} = settings) do
    get_disk_usage(settings, [])
  end

  def get_disk_usage(opts) do
    get_disk_usage(get(), opts)
  end

  def get_disk_usage do
    get_disk_usage(get(), [])
  end
end
