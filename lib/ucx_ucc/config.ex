defmodule UcxUcc.Config do
  @moduledoc """
  Handle general configuration.

  """

  @doc """
  Handle config items that may return :system tuple.

  """
  @spec get_env(atom, atom, any) :: any
  def get_env(app, item, default \\ nil) do
    case Application.get_env app, item, default do
      {:system, env} -> System.get_env(env) || default
      other -> other
    end
  end

  def deep_parse([]), do: []
  def deep_parse([h | t]), do: [deep_parse(h) | deep_parse(t)]
  def deep_parse({item, list}) when is_list(list) or is_tuple(list), do: {deep_parse(item), deep_parse(list)}
  def deep_parse({item, {:system, env}}), do: {item, System.get_env(env)}
  def deep_parse({:system, env}), do: System.get_env(env)
  def deep_parse({item, item2}), do: {item, item2}
  def deep_parse(item), do: item

  @doc """
  Handles updating a file based configuration file.

  Written originally for updating a `Conform` configuration file. However,
  it should work for any `key<delimiter>value/n` formatted file.

  ## replacement_keyword_list

  The input is given as either a keyword list or string pairs.

      list = ["key one": "replacement value 1", "key two": "replacement 2"]
      update_config("path/to/file.conf", list)

  ## Options

  * `delimiter` ("=") - provide the character(s) separating the key from the value
  * `create_backup` (false) - when set to true or some string, creates a backup
     of the file before writing. When set to `true`, the default extension
     `.uccsave` if used. This can be set by providing a string. If the backup
     file already exists, a numeric is appended to the name like `.uccsave.1`.
  """
  def update_config(path, replacement_keyword_list, opts \\ []) do
    if File.exists? path do
      path
      |> File.stream!([], :line)
      |> do_update_config(replacement_keyword_list, opts)
      |> write_file(path, opts)
    else
      {:error, :enoent}
    end
  end

  defp do_update_config(contents, [], _), do: contents

  defp do_update_config(contents, [{key, value} | rest], opts) do
    delim = opts[:delimiter] || :=
    replace = get_replace(value)

    contents
    |> Enum.map(&String.replace(&1, ~r/(#{key}\s*#{delim})(.*)$/, replace))
    |> do_update_config(rest, opts)
  end

  defp get_replace(value) when is_number(value) do
    ~s(\\1 #{value})
  end

  defp get_replace(value) when is_binary(value) do
    if String.match?(value, ~r/^[\d\.\:]+$/) do
      ~s(\\1 #{value})
    else
      ~s(\\1 "#{value}")
    end
  end

  defp get_replace(value) do
    ~s(\\1 #{inspect value})
  end

  defp write_file(contents, path, opts) do
    # creates a backup if the option has been provided
    create_backup!(path, opts)

    case File.write path, contents do
      :ok -> {:ok, contents}
      error -> error
    end
  end

  defp create_backup!(path, opts) do
    if backup_path = get_backup_path(path, opts[:create_backup] || false) do
      File.copy path, backup_path
    end
  end

  defp get_backup_path(_, false),
    do: false

  defp get_backup_path(path, true),
    do: get_backup_path(path, ".uccsave")

  defp get_backup_path(path, extension) do
    default = path <> extension
    if File.exists? default do
      next_backup_file_path(path, extension)
    else
      default
    end
  end

  defp next_backup_file_path(path, extension) do
    filename = path <> extension
    (filename <> "*")
    |> Path.wildcard()
    |> Enum.reduce([], fn file, acc ->
      case Regex.run ~r/(?:\.)(\d+)$/, file do
        [_, number] ->
          [String.to_integer(number) | acc]
        _ -> acc
      end
    end)
    |> case do
      [] -> filename <> ".1"
      list ->
        number = Enum.max(list) + 1
        filename <> "." <> to_string(number)
    end
  end

end
