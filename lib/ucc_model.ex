defmodule UccModel do
  @moduledoc """
  Model abstraction for UcxUcc
  """

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @repo opts[:repo] || UcxUcc.Repo
      @schema opts[:schema] || raise(":schema option required")

      import Ecto.Query, warn: false

      def new, do: %@schema{}
      def new(opts), do: struct(new(), opts)

      def schema, do: @schema

      def change(%@schema{} = schema, attrs) do
        @schema.changeset(schema, attrs)
      end

      def change(%@schema{} = schema) do
        @schema.changeset(schema)
      end

      def change(attrs) when is_map(attrs) or is_list(attrs) do
        @schema.changeset(%@schema{}, attrs)
      end

      def list do
        @repo.all @schema
      end

      def get(id, opts \\ []) do
        @repo.get @schema, id, opts
      end

      def get!(id, opts \\ []) do
        @repo.get! @schema, id, opts
      end

      def get_by(opts) do
        @repo.get_by @schema, opts
      end

      def get_by!(opts) do
        @repo.get_by! @schema, opts
      end

      def create(attrs \\ %{}) do
        @repo.insert change(attrs)
      end

      def create!(attrs \\ %{}) do
        @repo.insert! change(attrs)
      end

      def update(%@schema{} = schema, attrs) do
        @repo.update change(schema, attrs)
      end

      def update!(%@schema{} = schema, attrs) do
        @repo.update! change(schema, attrs)
      end

      def delete(%@schema{} = schema) do
        @repo.delete change(schema)
      end

      def delete(id) do
        @repo.delete get(id)
      end

      def delete!(%@schema{} = schema) do
        @repo.delete! change(schema)
      end

      def delete!(id) do
        @repo.delete! get(id)
      end

      def first do
        @schema |> first |> @repo.one
      end

      def last do
        @schema |> last |> @repo.one
      end

      defoverridable [
        delete: 1, delete!: 1, update: 2, update!: 2, create: 1, create!: 1,
        get_by: 1, get_by!: 1, get: 2, get!: 2, list: 0, change: 2, change: 1,
      ]
    end
  end
end
