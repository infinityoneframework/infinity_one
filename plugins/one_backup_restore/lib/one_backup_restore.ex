defmodule OneBackupRestore do
  @moduledoc """
  Backup and Restore the InfinityOne Application Data.

  Create Backups of InfinityOne data for general data recovery, server migrations,
  or disaster recovery. Restore backups previous created with the Backup feature.

  Backups are stored locally on the server and can be downloaded to the
  administrator's PC. One or more of the following can be included in the
  backup:

  * encrypted dump of the database
  * the main application's config file (i.e. Conform config file)
  * uploaded sound files
  * uploaded avatar images
  * uploaded attachment files

  ## Database Encryption

  For privacy, each database backup is encrypted with a private/public key
  pair. Before backing up the database, a new key pair (certificate) must be
  generated specifically for the Backup and Restore feature.

  Once a certificate is generated, the administrator should download the
  certificate and store it in a secure location for disaster recovery purposes.
  Without the certificate used go create a database backup, the backup can't be
  restored.

  ### Certificate Replacement

  In the event that an existing certificate is compromised, a new certificate
  can be generated. It will replace the previous certificate after creating a
  date stamped backup of it.

  The backup certificates are included in the tar file when downloading the
  certificates, for later (manual) recovery if needed.

  ## TODO

  * Implement backup file upload
  * Implement certificate upload
  * Implement REST API for the backup and restore features.
  * Implement a database adapter to support more than just mysql.

  ## Backup File Structure

  The backup file is an unencrypted tar file containing a `VERSION` text file
  and one or more of the following files:

  * database.backup (encrypted file)
  * infinity_one.conf
  * avatars.tgz
  * sounds.tgz
  * uploads.tgz
  """
  use Bitwise

  import OneBackupRestore.Utils

  require Logger

  @doc """
  Perform a backup.

  Creates the backup tar file including the backup components provided in
  the option list.
  """
  def backup(options) do
    config = config(options)
    try do
      config
      |> create_tempdir
      |> do_backup_database
      |> do_backup_configuration
      |> do_backup_avatars
      |> do_backup_sounds
      |> do_backup_attachments
      |> create_tarfile
    rescue
      e ->
        Logger.debug(fn -> inspect(e, label: "backup error") end)
        put_error(config, :backup, inspect(e))
    end
  end

  @doc """
  Perform a restore.

  Restores the backup including the backup components provided in
  the option list.
  """
  def restore(options) do
    config = config(options)
    try do
      config
      |> unpack_tarfile()
      |> do_restore_database()
      |> do_restore_configuration()
      |> do_restore_avatars()
      |> do_restore_sounds()
      |> do_restore_attachments()
    rescue
      e ->
        Logger.debug(fn -> inspect(e, label: "restore error") end)
        put_error(config, :restore, inspect(e))
    end
  end

  defp config(options) do
    env = InfinityOne.env()
    name = InfinityOne.name()
    repo_name = name |> Application.get_env(:ecto_repos) |> hd
    repo = name |> Application.get_env(repo_name)

    Enum.into(
      [
        name: name,
        db_name: repo[:database],
        db_password: repo[:password],
        env: env,
        error?: false,
        errors: []
      ], options)
  end

  @doc false
  def backup_database(path, database, config) do
    fname = Path.join(path, database_backup_name())
    "mysqldump"
    |> System.cmd(mysql_args(config) ++ ~w(--add-drop-database --databases #{database}))
    |> case do
      {contents, 0} ->
        encrypt_and_write fname, contents
        {:ok, fname}

      _ ->
        {:error, "Problem creating the backup"}
    end
  end

  @doc false
  def restore_database(fname, database, config) do
    tmp_fname = "#{fname}.#{:rand.uniform(1000)}.tmp"

    mysql_args = mysql_args(config) ++ [database, "-e", "source #{tmp_fname}"]

    with contents <- read_and_decrypt(fname),
         :ok <- File.write(tmp_fname, contents),
         {_res, 0} <- System.cmd("mysql", mysql_args),
         :ok <- File.rm(tmp_fname) do
      {:ok, fname}
    else
      {:error, error}  -> {:error, error}
      {message, errno} -> {:error, "Error: #{errno} - #{message}"}
      other            -> {:error, inspect(other)}
    end
  end

  defp create_tempdir(config) do
    case Briefly.create(directory: true) do
      {:ok, path} ->
        File.write!(Path.join(path, "VERSION"), InfinityOne.version())
        Map.put(config, :path, path)

      {:error, error} ->
        put_error(config, :create_tempdir, error)
    end
  end

  defp unpack_tarfile(config) do
    case untar_backup(config.backup_name) do
      {:ok, %{path: path}} ->
        Map.put(config, :path, path)
      {:error, error} ->
        put_error(config, :unpack_tarfile, error)
    end
  end

  defp do_backup_database(%{database: true, error?: false} = config) do
    case backup_database(config.path, database_name(config), config) do
      {:ok, _}        -> config
      {:error, error} -> put_error(config, :database, error)
    end
  end

  defp do_backup_database(config), do: config

  defp do_restore_database(%{database: true, error?: false} = config) do
    fpath = Path.join(config.path, "database.backup")
    case restore_database(fpath, database_name(config), config) do
      {:ok, _}        -> config
      {:error, error} -> put_error(config, :database, error)
    end
  end

  defp do_restore_database(config), do: config

  defp do_backup_configuration(%{configuration: true, error?: false} = config) do
    target = Path.join(config.path, config_file())
    case File.cp config_path(), target do
      :ok ->
        config
      {:error, error} ->
        put_error(config, :configuration, to_string(error))
    end
  end

  defp do_backup_configuration(config), do: config

  defp do_restore_configuration(%{configuration: true, error?: false} = config) do
    source = Path.join(config.path, config_file())
    case File.cp source, config_path() do
      :ok             -> config
      {:error, error} -> put_error(config, :configuration, to_string(error))
    end
  end

  defp do_restore_configuration(config), do: config

  defp do_backup_avatars(%{avatars: true, error?: false} = config) do
    dest_file = Path.join(config.path, "avatars.tgz")
    case System.cmd("tar", ~w(czf #{dest_file} -C #{avatars_path(config.env)} .)) do
      {_, 0}         -> config
      {error, errno} -> put_error(config, :do_backup_avatars, "Error #{errno}: #{error}")
    end
  end

  defp do_backup_avatars(config), do: config

  defp do_restore_avatars(%{avatars: true, error?: false} = config) do
    src_file = Path.join(config.path, "avatars.tgz")
    case System.cmd("tar", ~w(xzf #{src_file} -C #{avatars_path(config.env)})) do
      {_, 0}         -> config
      {error, errno} -> put_error(config, :do_restore_avatars, "Error #{errno}: #{error}")
    end
  end

  defp do_restore_avatars(config), do: config

  defp do_backup_sounds(%{sounds: true, error?: false} = config) do
    dest_file = Path.join(config.path, "sounds.tgz")
    case System.cmd("tar", ~w(czf #{dest_file} -C #{sounds_path(config.env)} .)) do
      {_, 0}         -> config
      {error, errno} -> put_error(config, :do_backup_sounds, "Error #{errno}: #{error}")
    end
  end

  defp do_backup_sounds(config), do: config

  defp do_restore_sounds(%{sounds: true, error?: false} = config) do
    src_file = Path.join(config.path, "sounds.tgz")
    case System.cmd("tar", ~w(xzf #{src_file} -C #{sounds_path(config.env)})) do
      {_, 0}         -> config
      {error, errno} -> put_error(config, :do_restore_sounds, "Error #{errno}: #{error}")
    end
  end

  defp do_restore_sounds(config), do: config

  defp do_backup_attachments(%{attachments: true, error?: false} = config) do
    dest_file = Path.join(config.path, "uploads.tgz")
    case System.cmd("tar", ~w(czf #{dest_file} -C #{uploads_path(config.env)} .)) do
      {_, 0}         -> config
      {error, errno} -> put_error(config, :do_backup_attachments, "Error #{errno}: #{error}")
    end
  end

  defp do_backup_attachments(config), do: config

  defp do_restore_attachments(%{attachments: true, error?: false} = config) do
    src_file = Path.join(config.path, "uploads.tgz")
    case System.cmd("tar", ~w(xzf #{src_file} -C #{uploads_path(config.env)})) do
      {_, 0}         -> config
      {error, errno} -> put_error(config, :do_restore_attachments, "Error #{errno}: #{error}")
    end
  end

  defp do_restore_attachments(config), do: config

  defp create_tarfile(%{error?: false} = config) do
    out_path = backup_path(config.env)
    fname = base_name config.name, config.env
    out_fname = Path.join(out_path, fname <> ".tgz")
    case System.cmd("tar", ~w(cf #{out_fname} -C #{config.path} .)) do
      {_, 0} ->
        config

      {error, code} ->
        put_error(config, :create_tarfile, "#{code}: #{error}")
    end
  end

  defp create_tarfile(config), do: config

  defp put_error(config, key, error) do
    config
    |> put_in([:error?], true)
    |> update_in([:errors], & [{key, error} | &1])
  end

  @doc """
  Gets a list of all the backups on the server.

  Returns a list of file names and their details, sorted by `mtime`.
  """
  def get_backups do
    InfinityOne.env()
    |> backup_path()
    |> Path.join("*")
    |> Path.wildcard()
    |> Enum.map(fn path ->
      base_name = Path.basename(path)
      info = lstat(path)
      %{
        dt: info[:dt],
        type: info[:type],
        mtime: info[:mtime],
        path: path,
        base_name: base_name,
        root_name: Path.rootname(base_name),
        ext: Path.extname(base_name)
      }
    end)
    |> Enum.filter(& &1.type == :regular)
    |> Enum.sort(& &1.mtime > &2.mtime)
  end

  defp lstat(path) do
    case File.lstat(path) do
      {:ok, stat} ->
        %{
          dt: NaiveDateTime.from_erl!(stat.mtime) |> NaiveDateTime.to_string(),
          type: stat.type,
          mtime: stat.mtime
        }
      _ ->
        %{}
    end
  end

  defp mysql_args(%{db_password: password}) do
    ~w(-u root -p#{password})
  end

  defp database_name(config) do
    config.db_name
  end

end
