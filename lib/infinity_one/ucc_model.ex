defmodule OneModel do
  @moduledoc """
  Model abstraction for InfinityOne.

  """

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @repo opts[:repo] || InfinityOne.Repo
      @schema opts[:schema] || raise(":schema option required")

      @type id :: integer | String.t

      import Ecto.Query, warn: false

      @doc """
      Create a default #{@schema} struct.
      """
      @spec new() :: Struct.t
      def new, do: %@schema{}

      @doc """
      Create a #{@schema} with the provided options.
      """
      @spec new(Keyword.t) :: Struct.t
      def new(opts), do: struct(new(), opts)

      @doc """
      Return the schema module.
      """
      @spec schema() :: Module.t
      def schema, do: @schema

      @doc """
      Returns an `%Ecto.Changeset{}` for tracking #{@schema} changes.
      """
      @spec change(Struct.t, Keyword.t) :: Ecto.Changeset.t
      def change(%@schema{} = schema, attrs) do
        @schema.changeset(schema, attrs)
      end

      @doc """
      Returns an `%Ecto.Changeset{}` for tracking #{@schema} changes.
      """
      @spec change(Struct.t) :: Ecto.Changeset.t
      def change(%@schema{} = schema) do
        @schema.changeset(schema)
      end

      @spec change(Keyword.t) :: Ecto.Changeset.t
      def change(attrs) when is_map(attrs) or is_list(attrs) do
        @schema.changeset(%@schema{}, attrs)
      end


      @doc """
      Get a list of #{@schema}'s.

      ## Options'

      * `preload: list`
      """
      @spec list(Keword.t) :: [Struct.t]
      def list(opts \\ []) do
        if preload = opts[:preload] do
          @schema
          |> preload(^preload)
          |> order_by(asc: :inserted_at)
          |> @repo.all
        else
          @repo.all @schema
        end
      end

      @doc """
      Get a list of #{@schema},s given a list of field value pairs.

      ## Preload

      Pass a list of preloads with the `:preload` key.

      ## Examples

          #{@schema}.list_by field1: value1, field2: field2, preload: [:association]
      """
      @spec list_by(Keyword.t) :: List.t
      def list_by(opts) do
        {preload, opts} = Keyword.pop(opts, :preload, [])

        opts
        |> Enum.reduce(@schema, fn {k, v}, query ->
          where(query, [b], field(b, ^k) == ^v)
        end)
        |> preload(^preload)
        |> order_by(asc: :inserted_at)
        |> @repo.all
      end

      @doc """
      Get a single #{@schema}.

      ## Preload

      Pass a list of preloads with the `:preload` key.
      """
      @spec get(id, Keyword.t) :: Struct.t
      def get(id, opts \\ []) do
        if preload = opts[:preload] do
          @repo.one from s in @schema, where: s.id == ^id, preload: ^preload
        else
          @repo.get @schema, id, opts
        end
      end

      @spec get!(id, Keyword.t) :: Struct.t
      def get!(id, opts \\ []) do
        if preload = opts[:preload] do
          @repo.one! from s in @schema, where: s.id == ^id, preload: ^preload
        else
          @repo.get! @schema, id, opts
        end
      end

      @spec get_by(Keyword.t) :: Struct.t
      def get_by(opts) do
        if preload = opts[:preload] do
          # TODO: Fix this with a single query
          @schema
          |> @repo.get_by(Keyword.delete(opts, :preload))
          |> @repo.preload(preload)
        else
          @repo.get_by @schema, opts
        end
      end

      @spec get_by!(Keyword.t) :: Struct.t
      def get_by!(opts) do
        if preload = opts[:preload] do
          @schema
          |> @repo.get_by(Keyword.delete(opts, :preload))
          |> @repo.preload(preload)
        else
          @repo.get_by! @schema, opts
        end
      end

      @spec create(Ecto.Changeset.t | Keyword.t | Map.t) :: {:ok, Struct.t} |
                                                            {:error, Ecto.Changeset.t}
      def create(changeset_or_attrs \\ %{})

      def create(%Ecto.Changeset{} = changeset) do
        @repo.insert changeset
      end

      def create(attrs) do
        create change(attrs)
      end

      def create!(changeset_or_attrs \\ %{})

      @spec create!(Ecto.Changeset.t) :: Struct.t | no_return
      def create!(%Ecto.Changeset{} = changeset) do
        @repo.insert! changeset
      end

      @spec create!(Keyword.t) :: Struct.t | no_return
      def create!(attrs) do
        create! change(attrs)
      end

      @spec update(Ecto.Changeset.t) :: {:ok, Struct.t} |
                                        {:error, Ecto.Changeset.t}
      def update(%Ecto.Changeset{} = changeset) do
        @repo.update changeset
      end

      @spec update(Struct.t, Keyword.t) :: {:ok, Struct.t} |
                                           {:error, Ecto.Changeset.t}
      def update(%@schema{} = schema, attrs) do
        schema
        |> change(attrs)
        |> update
      end

      @spec update!(Ecto.Changeset.t) :: Struct.t | no_return
      def update!(%Ecto.Changeset{} = changeset) do
        @repo.update! changeset
      end

      @spec update!(Struct.t, Keyword.t) :: Struct.t | no_return
      def update!(%@schema{} = schema, attrs) do
        schema
        |> change(attrs)
        |> update!
      end

      @spec delete(Struct.t) :: {:ok, Struct.t} |
                                {:error, Ecto.Changeset.t}
      def delete(%@schema{} = schema) do
        delete change(schema)
      end

      @doc """
      Delete the #{@schema} given by an `Ecto.Changeset`.
      """
      @spec delete(Ecto.Changeset.t) :: {:ok, Struct.t} |
                                        {:error, Ecto.Changeset.t}
      def delete(%Ecto.Changeset{} = changeset) do
        @repo.delete changeset
      end

      @doc """
      Delete the #{@schema} given by an id.
      """
      @spec delete(id) :: {:ok, Struct.t} |
                          {:error, Ecto.Changeset.t}
      def delete(id) do
        delete get(id)
      end

      @doc """
      Delete the #{@schema} given a the struct, or raise an exception.
      """
      @spec delete!(Struct.t) :: Struct.t | no_return
      def delete!(%@schema{} = schema) do
        delete! change(schema)
      end

      @doc """
      Delete the #{@schema} given a changeset, or raise an exception.
      """
      @spec delete!(Ecto.Changeset.t) :: {:ok, Struct.t} |
                                        {:error, Ecto.Changeset.t}
      def delete!(%Ecto.Changeset{} = changeset) do
        @repo.delete! changeset
      end

      @doc """
      Delete the given #{@schema} by id, or raise an exception.
      """
      @spec delete!(id) :: Struct.t | no_return
      def delete!(id) do
        delete! get(id)
      end

      @doc """
      Delete all #{@schema}'s.
      """
      # @spec delete_all() :: any
      def delete_all do
        @repo.delete_all @schema
      end

      @doc """
      Get the first #{@schema} ordered by creation date
      """
      @spec first() :: Struct.t | nil
      def first do
        @schema
        |> order_by(asc: :inserted_at)
        |> first
        |> @repo.one
      end

      @doc """
      Get the last #{@schema} ordered by creation date
      """
      @spec last() :: Struct.t | nil
      def last do
        @schema
        |> order_by(asc: :inserted_at)
        |> last
        |> @repo.one
      end

      @doc """
      Preload a #{@schema}.
      """
      def preload_schema(schema, preload) do
        @repo.preload schema, preload
      end

      defoverridable [
        delete: 1, delete!: 1, update: 1, update: 2, update!: 1,
        update!: 2, create: 1, create!: 1, get_by: 1, get_by!: 1,
        get: 2, get!: 2, list: 0, change: 2, change: 1, delete_all: 0,
        preload_schema: 2
      ]
    end
  end
end
