defmodule UccSettings.Settings do
  @moduledoc """
  The boundary for the Settings system.

  This module exposes a database backed application configuration
  as a ucx_ucc plugin

  ## Usage

  Create a new module for a specific class of settings (socope) using
  this module to add the required behaviour.

      defmodule UccSettings.Settings.Config.General do
        use UccSettings.Settings, scope: inspect(__MODULE__), repo: UccSettings.Repo, shcema: [
            [name: "site_title", type: "string", default: "UcxUcc"],
            [name: "one", type: "integer", default: 0]]
      end
  """

  defmacro __using__(opts) do
    scope = opts[:scope]
    unless scope do
      raise ":scope option is required"
    end
    repo = opts[:repo]
    unless repo do
      raise ":repo option is required"
    end
    schema = opts[:schema]
    unless schema do
      raise ":schema option is required"
    end

    # @modules scope
    # Module.put_attribute __MODULE__, :modules, scope

    quote bind_quoted: [repo: repo, scope: scope, schema: schema] do
      import Ecto.Query

      @config UccSettings.Settings.Config
      @scope scope
      @repo repo
      @schema schema

      @fields Enum.map(@schema, &({get_in(&1, [:name]) |> String.to_atom, get_in(&1, [:default]) |> inspect}))
      @types Enum.map(@schema, &({get_in(&1, [:name]) |> String.to_atom, get_in(&1, [:type])})) |> Enum.into(%{})

      defstruct @fields


      def new do
        __MODULE__.__struct__
      end
      def new(opts) do
        opts = Enum.into opts, %{}
        struct new(), opts
      end

      def fields, do: Enum.map(@fields, &elem(&1, 0))

      @doc """
      Initialize the database with the configured defaults.
      """
      def init do
        @schema
        |> Enum.map(fn item ->
          params =
            item
            |> Enum.into(%{})
            |> Map.put(:scope, @scope)
            |> Map.put(:value, item[:default])
          @repo.insert_or_update @config.changeset(%@config{}, params)
        end)
      end

      @doc """
      Delete all records form the db for this scoping
      """
      def delete_all do
        get()
        |> Enum.map(& @repo.delete(&1))
      end

      @doc """
      Load the configuation struct from the database.
      """
      def load do
        get()
        |> Enum.map(& {String.to_atom(&1.name), &1.value})
        |> new
      end

      @doc """
      Gets all the fields from the database.


      """
      def get do
        @repo.all(from c in @config, where: c.scope == @scope)
        |> Enum.map(&UccSettings.Settings.cast/1)
      end


      @doc """
      Get a specific field from the database.
      """
      def get(name) do
        @repo.one(from c in @config, where: c.scope == @scope and c.name == ^name)
        |> cast(name)
      end

      # not sure I need this...
      # def update(general) do
      #   # Repo.update UccConfig.changeset(setting, %{value: value})
      # end

      @doc """
      Update a field in the database
      """
      def update(name, value) do
        setting = get(name)
        value = UccSettings.Settings.cast value
        @repo.update @config.changeset(setting, %{value: value})
      end

      # Dynamically create fuctions for each of the fields.
      @fields
      |> Keyword.keys
      |> Enum.map(fn name ->
        @doc """
        Field accessor

        Load the field from the database. Names are give as strings.
        """
        def unquote(name)() do
          load()
          |> Map.get(unquote(name))
          |> cast(unquote(name))
        end

        def unquote(name)(config) do
          config
          |> Map.get(unquote(name))
          |> cast(unquote(name))
        end
      end)

      def cast(value, name) when is_binary(value) do
        value = if Regex.match?(~r/^".*"$/, value),
          do: String.replace(value, "\"", ""), else: value
        UccSettings.Settings.cast @types[name], value
      end

      def cast(value, name) do
        UccSettings.Settings.cast @types[name], value
      end

      defoverridable [new: 0, new: 1, init: 0, load: 0, get: 0, get: 1, update: 2, cast: 2]
    end
  end

  import Ecto.{Query, Changeset}, warn: false
  alias UcxUcc.Repo

  alias UccSettings.Settings.Config

  Module.register_attribute __MODULE__,
    :modules, accumulate: true, persist: true

  def modules, do: @modules
  @doc """
  Returns the list of configs.

  ## Examples

      iex> list_configs()
      [%Config{}, ...]

  """
  def list_configs do
    Repo.all(Config)
  end

  @doc """
  Gets a single config.

  Raises `Ecto.NoResultsError` if the Config does not exist.

  ## Examples

      iex> get_config!(123)
      %Config{}

      iex> get_config!(456)
      ** (Ecto.NoResultsError)

  """
  def get_config!(id), do: Repo.get!(Config, id)

  @doc """
  Creates a config.

  ## Examples

      iex> create_config(%{field: value})
      {:ok, %Config{}}

      iex> create_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_config(attrs \\ %{}) do
    %Config{}
    |> config_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a config.

  ## Examples

      iex> update_config(config, %{field: new_value})
      {:ok, %Config{}}

      iex> update_config(config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_config(%Config{} = config, attrs) do
    config
    |> config_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Config.

  ## Examples

      iex> delete_config(config)
      {:ok, %Config{}}

      iex> delete_config(config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_config(%Config{} = config) do
    Repo.delete(config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking config changes.

  ## Examples

      iex> change_config(config)
      %Ecto.Changeset{source: %Config{}}

  """
  def change_config(%Config{} = config) do
    config_changeset(config, %{})
  end

  defp config_changeset(%Config{} = config, attrs) do
    config
    |> cast(attrs, [:name, :scope, :type, :value, :default])
    |> validate_required([:name, :scope, :type, :value, :default])
  end

  def cast(%{type: type, value: value} = setting) do
    Map.put setting, :value, cast(type, value)
  end

  def cast(value) when is_atom(value) or is_number(value) or is_float(value), do: to_string(value)
  def cast(list) when is_list(list), do: inspect(list)
  def cast(value), do: value

  def cast("string", value), do: to_string(value)
  def cast("integer", value) when is_integer(value), do: value
  def cast("integer", value), do: Integer.parse(value) |> elem(0)
  def cast("boolean", value) when value in ["true", "false"], do: String.to_atom(value)
  def cast("boolean", value) when value in [true, false], do: value
  def cast("boolean", nil), do: false
  def cast(input = "{:array," <> type, value) do
    type =
      case Regex.run ~r/:([a-z]+).*/, String.trim(type) do
        [_, type] -> type
        _ -> raise "could not cast #{inspect input}"
      end
    case Regex.run(~r/^\[(.*)\]$/, String.trim(value)) do
      [_, list] ->
        list
        |> String.split(",", trim: true)
        |> Enum.map(fn item ->
          value =
            item
            |> String.replace(~r/\s*"/, "")
            |> String.trim
          cast(type, value)
         end)
      error ->
        raise "problem parse array #{inspect error}"
    end
  end

end
