defmodule UccBackupRestore.Schema.Backup do
  @doc """
  Virtual Ecto schema definition for backups.

  There is no database table for this schema definition. It is used for creating
  changesets only.
  """
  use UccChat.Shared, :schema

  schema "backups" do
    field :database, :boolean, default: true, virtual: true
    field :configuration, :boolean, default: true, virtual: true
    field :avatars, :boolean, default: true, virtual: true
    field :sounds, :boolean, default: true, virtual: true
    field :attachments, :boolean, default: true, virtual: true
    field :file, :string, virtual: true
  end

  @fields ~w(attachments configuration database avatars sounds file)a

  def model, do: UccBackupRestore.Backup

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    cast(struct, params, @fields)
  end
end
