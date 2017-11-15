defmodule UccModel do
  @moduledoc """
  Model abstraction for UcxUcc
  """

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @repo opts[:repo] || UcxUcc.Repo
      @schema opts[:schema] || raise(":schema option required")

      @type id :: integer | String.t

      import Ecto.Query, warn: false

      @spec new() :: Struct.t
      def new, do: %@schema{}

      @spec new(Keyword.t) :: Struct.t
      def new(opts), do: struct(new(), opts)

      @spec schema() :: Module.t
      def schema, do: @schema

      @spec change(Struct.t, Keyword.t) :: Ecto.Changeset.t
      def change(%@schema{} = schema, attrs) do
        @schema.changeset(schema, attrs)
      end

      @spec change(Struct.t) :: Ecto.Changeset.t
      def change(%@schema{} = schema) do
        @schema.changeset(schema)
      end

      @spec change(Keyword.t) :: Ecto.Changeset.t
      def change(attrs) when is_map(attrs) or is_list(attrs) do
        @schema.changeset(%@schema{}, attrs)
      end

      @spec list() :: [Struct.t]
      def list do
        @repo.all @schema
      end


      @spec list_by(Keyword.t) :: List.t
      def list_by(opts) do
        {preload, opts} = Keyword.pop(opts, :preload, [])

        opts
        |> Enum.reduce(@schema, fn {k, v}, query ->
          where(query, [b], field(b, ^k) == ^v)
        end)
        |> preload(^preload)
        |> @repo.all
      end

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

      @spec create(Ecto.Changeset.t) :: {:ok, Struct.t} |
                                        {:error, Ecto.Changeset.t}

      def create(changeset_or_attrs \\ %{})

      def create(%Ecto.Changeset{} = changeset) do
        @repo.insert changeset
      end

      @spec create(Keyword.t) :: {:ok, Struct.t} |
                                 {:error, Ecto.Changeset.t}
      def create(attrs) do
        @repo.insert change(attrs)
      end

      def create!(changeset_or_attrs \\ %{})

      @spec create!(Ecto.Changeset.t) :: Struct.t | no_return
      def create!(%Ecto.Changeset{} = changeset) do
        @repo.insert! changeset
      end

      @spec create!(Keyword.t) :: Struct.t | no_return
      def create!(attrs) do
        @repo.insert! change(attrs)
      end

      @spec update(Struct.t, Keyword.t) :: {:ok, Struct.t} |
                                           {:error, Ecto.Changeset.t}
      def update(%Ecto.Changeset{} = changeset) do
        @repo.update changeset
      end
      def update(%@schema{} = schema, attrs) do
        @repo.update change(schema, attrs)
      end

      @spec update!(Struct.t, Keyword.t) :: Struct.t | no_return
      def update!(%Ecto.Changeset{} = changeset) do
        @repo.update! changeset
      end
      def update!(%@schema{} = schema, attrs) do
        @repo.update! change(schema, attrs)
      end

      @spec delete(Struct.t) :: {:ok, Struct.t} |
                                {:error, Ecto.Changeset.t}
      def delete(%@schema{} = schema) do
        @repo.delete change(schema)
      end

      @spec delete(id) :: {:ok, Struct.t} |
                          {:error, Ecto.Changeset.t}
      def delete(id) do
        @repo.delete get(id)
      end

      @spec delete!(Struct.t) :: Struct.t | no_return
      def delete!(%@schema{} = schema) do
        @repo.delete! change(schema)
      end

      @spec delete!(id) :: Struct.t | no_return
      def delete!(id) do
        @repo.delete! get(id)
      end

      # @spec delete_all() :: any
      def delete_all do
        @repo.delete_all @schema
      end

      @spec first() :: Struct.t | nil
      def first do
        @schema
        |> order_by(asc: :inserted_at)
        |> first
        |> @repo.one
      end

      @spec last() :: Struct.t | nil
      def last do
        @schema
        |> order_by(asc: :inserted_at)
        |> last
        |> @repo.one
      end

      def preload_schema(schema, preload) do
        @repo.preload schema, preload
      end

      defoverridable [
        delete: 1, delete!: 1, update: 2, update!: 2, create: 1, create!: 1,
        get_by: 1, get_by!: 1, get: 2, get!: 2, list: 0, change: 2, change: 1,
        delete_all: 0, preload_schema: 2
      ]
    end
  end
end
