# This file is responsible for parsing SSL certificates from
# ssl configuration file to be used for Mscs web server.

defmodule UcxUcc.CertManager do
  @moduledoc """

  Handle finding ssl certificates on the UCx.

  General functions to manage ssl certificate files on a UCx.
  """

  require Logger

  @ssl_conf_file "/etc/httpd/conf.d/ssl.conf"
  @ssl_cert "SSLCertificateFile"
  @ssl_cert_key "SSLCertificateKeyFile"
  @ssl_ca_cert "SSLCACertificateFile"

  @doc """
  Parses the ssl configuration file and returns list of file names.

  Returns the `certfile`, `cacertfile`, and `keyfile` file names.
  If the `cacertfile` is not found, the `certfile` will be returned.

  ## Examples

      get_cert_file        # uses the default #{@ssl_conf_file} file

      get_cert_file(:mscs) # gets the config filename from the config
                           # using the app key give (`:mscs`)

      get_cert_file("/etc/ssl.conf")  # uses config file name given

  """
  def get_cert_info(name \\ @ssl_conf_file)
  def get_cert_info(app) when is_atom(app) do
    Application.get_env(app, :ssl_conf_file, @ssl_conf_file)
    |> get_cert_info
  end
  def get_cert_info(ssl_conf_file) do
    File.stream!(ssl_conf_file, [], :line)
    |> Enum.reduce([], fn(line, acc) ->
      line = Regex.replace ~r/#.*/, line, ""
      cond do
        value = find_key(@ssl_cert, line) ->
          value = String.strip value
          Keyword.put(acc, :certfile, value)
          |> Keyword.put_new(:cacertfile, value)
        value = find_key(@ssl_cert_key, line) ->
          Keyword.put(acc, :keyfile, String.strip(value))
        value = find_key(@ssl_ca_cert, line) ->
          Keyword.put(acc, :cacertfile, String.strip(value))
        true -> acc
      end
    end)
  end

  @doc """
  Set the endpoint cert names.

  Sets the applications EndPoint :https cert file names. Call this
  from the main supervisor, before starting the EndPoint.

  ## Example

      set_endpoint_certs!(:mscs, Mscs.EndPoint)
  """
  def set_endpoint_certs!(app, endpoint_mod) do
    endpoint = Application.get_env(app, endpoint_mod)
    https = get_cert_info(app)
    |> Enum.reduce(endpoint[:https] || [], fn({k,v}, https) ->
      if(Keyword.get(https, k) != nil) do
        https
      else
        Keyword.put(https, k, v)
      end
    end)
    Application.put_env app, endpoint_mod, Keyword.put(endpoint, :https, https)
  end

  ##############
  # Private

  defp find_key(key, line) do
    case Regex.run(~r/#{key}[\s]+(.+)$/, line) do
      [_, result] ->
        String.strip(result)
      _ -> nil
    end
  end

end
