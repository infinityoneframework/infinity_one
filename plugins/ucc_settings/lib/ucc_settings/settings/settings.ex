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

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Ecto.{Query, Changeset}, warn: false

      @repo   opts[:repo] || UcxUcc.Repo
      @schema opts[:schema] || raise("schema option required")
      @fields @schema.__schema__(:fields)

      def new do
        @schema.__struct__
      end
      def new(opts) do
        opts = Enum.into opts, %{}
        struct new(), opts
      end

      def key do
        UccSettings.Utils.module_key __MODULE__
      end

      @doc """
      Initialize the database with the configured defaults.
      """
      def init do
        @repo.insert_or_update __MODULE__.changeset(new())
      end

      @doc """
      Delete all records form the db for this scoping
      """
      def delete_all do
        @repo.delete get()
      end

      @doc """
      Gets all the fields from the database.
      """
      def get do
        @repo.one from c in @schema, limit: 1
      end

      def get(name) do
        Map.get get(), name
      end

      def get(config, name) do
        Map.get config, name
      end

      def schema do
        @schema
      end

      def update(%@schema{} = settings) do
        @repo.update __MODULE__.changeset(get(), Map.from_struct(settings))
      end


      @doc """
      Update a field in the database
      """
      def update(name_or_schema, value \\ %{})

      def update(%@schema{} = settings, params) do
        @repo.update __MODULE__.changeset(settings, params)
      end

      def update(name, value) do
        @repo.update __MODULE__.changeset(get(), %{name => value})
      end

      def changeset(schema, params \\ %{}) do
        @schema.changeset schema, params
      end

      # Dynamically create fuctions for each of the fields.
      @fields
      |> Enum.map(fn name ->
        @doc """
        Field accessor

        Load the field from the database. Names are give as strings.
        """
        def unquote(name)() do
          get()
          |> Map.get(unquote(name))
        end

        def unquote(name)(%UccSettings{} = config) do
          config
          |> Map.get(key())
          |> Map.get(unquote(name))
        end
        def unquote(name)(config) do
          config
          |> Map.get(unquote(name))
        end
      end)


      defoverridable [new: 0, new: 1, init: 0, get: 0, get: 1, get: 2,
        update: 2, changeset: 2, schema: 0]
    end
  end

end
