defmodule OneBackupRestore.Utils do
  @moduledoc """
  Utility functions for Backup and Restore

  Various shared functions to support Backup, Restore and Certificate
  management.
  """

  import InfinityOneWeb.Gettext

  alias OneBackupRestore.Config

  require Logger

  @keys_path        Config.get_env(:keys_path) || raise("keys_path required")
  @private_key_path Path.join(@keys_path, "private.pem")
  @public_key_path  Path.join(@keys_path, "public.pem")

  @config_file "infinity_one.conf"
  @config_dirname Config.get_env(:config_dirname) || raise("config_dirname required")
  @config_path Path.join(@config_dirname, @config_file)
  @attachments_name "uploads"


  def config_file, do: @config_file
  def config_dirname, do: @config_dirname
  def config_path, do: @config_path
  def attachments_name, do: @attachments_name

  @doc """
  Return the keys path.
  """
  def keys_path, do: @keys_path

  def encrypt_and_write(fname, contents) do
    File.write fname, encrypt(contents)
  end

  def encrypt(contents) do
    key = :crypto.strong_rand_bytes(16)
    iv = :crypto.strong_rand_bytes(16)
    {_p_key, s_key} = get_keys()
    encrypted_content = :crypto.block_encrypt :aes_cfb128, key, iv, contents
    encryped_key = :public_key.encrypt_private(key <> iv, s_key)
    len = encryped_key |> byte_size |> to_string |> String.pad_leading(10, "0")
    [len, encryped_key, encrypted_content]
  end

  def read_and_decrypt(fname) do
    fname
    |> File.read!()
    |> decrypt()
  end

  def decrypt(encrypted_file) do
    <<len :: binary-size(10), rest::bitstring>> = encrypted_file
    len_int = String.to_integer(len)
    {p_key, _s_key} = get_keys()

    <<encrypted_key::binary-size(len_int), encrypted_content::bitstring>> = rest
    <<key::binary-size(16), iv::binary-size(16)>> = :public_key.decrypt_public(encrypted_key, p_key)

    :crypto.block_decrypt(:aes_cfb128, key, iv, encrypted_content)
  end

  def get_keys do
    {private, public} = keys()
    {:ok, raw_s_key} = File.read(private)
    {:ok, raw_p_key} = File.read(public)

    [enc_s_key] = :public_key.pem_decode(raw_s_key)
    s_key = :public_key.pem_entry_decode(enc_s_key)

    [enc_p_key] = :public_key.pem_decode(raw_p_key)
    p_key = :public_key.pem_entry_decode(enc_p_key)
    {p_key, s_key}
  end

  def database_backup_name(_name \\ nil) do
    "database.backup"
  end

  def datetime_now do
    DateTime.utc_now
    |> to_string
    |> String.replace(~r/([\-\: ])|(\..*)$/, "")
  end

  def base_name(brand_name, :prod) do
    "#{brand_name}-" <> datetime_now()
  end

  def base_name(brand_name, env) do
    "#{brand_name}-#{env}-" <> datetime_now()
  end

  def app_dir(env \\ InfinityOne.env())

  def app_dir(:prod) do
    Application.app_dir(:infinity_one)
  end

  def app_dir(_) do
    ""
  end

  def backup_path(env \\ InfinityOne.env()) do
    Path.join [app_dir(env) | ~w(priv static backups)]
  end

  def uploads_path(env) do
    Path.join([app_dir(env) | ~w(priv static uploads)])
  end

  def avatars_path(env) do
    Path.join([app_dir(env) | ~w(priv static avatar)])
  end

  def sounds_path(env) do
    Path.join([app_dir(env) | ~w(priv static sounds)])
  end

  def web_tmp_path(env \\ InfinityOne.env()) do
    Path.join([app_dir(env) | ~w(priv static tmp)])
  end

  def delete_backup(file, env \\ InfinityOne.env()) do
    env
    |> backup_path()
    |> Path.join(file)
    |> File.rm
  end

  def untar_backup(name) do
    tar_path = Path.join(backup_path(), name)

    with {:ok, path} <- Briefly.create(directory: true),
         {_, 0} <- System.cmd("tar", ~w(xf #{tar_path} -C #{path})),
         {:ok, contents} <- File.ls(path) do
      {:ok, %{path: path, orig_path: tar_path, contents: contents}}
    else
      error ->
        {:error, error}
    end
  end

  def download_cert({key, _cert}) do
    tmp_path = Path.join(web_tmp_path(), UUID.uuid1() <> ".tgz")
    src_path = Path.dirname(key)

    with {:ok, path} <- Briefly.create(directory: true),
         {:ok, _} <- File.cp_r(src_path, path),
         {_, 0} <- System.cmd("tar", ~w(czf #{tmp_path} -C #{path} .)) do

      {:ok, tmp_path}
    else
      _ -> {:error, ~g(Could not create cert backup.)}
    end
  end

  def backup_keys({key, cert}) do
    now = datetime_now()
    with :ok <- File.cp(key, key <> "-" <> now) do
      File.cp(cert, cert <> "-" <> now)
      reset_keys_permissions({key, cert})
      :ok
    end
  end

  def reset_keys_permissions({key, cert}) do
    File.chmod(key, 0o400)
    File.chmod(cert, 0o400)
  end

  def write_keys_permissions({key, cert}) do
    File.chmod(key, 0o600)
    File.chmod(cert, 0o600)
  end

  def keys do
    {@private_key_path, @public_key_path}
  end

  def keys_exist? do
    {key, cert} = keys()
    File.exists?(key) and File.exists?(cert)
  end

  def conf_file_exists? do
    File.exists?(config_path())
  end

  def batch_delete_backups(backups) do
    Enum.reduce(backups, {:ok, []}, fn backup, {code, list} ->
      case backup_path() |> Path.join(backup) |> File.rm do
        :ok -> {code, [backup | list]}
        _   -> {:error, list}
      end
    end)
  end
end
