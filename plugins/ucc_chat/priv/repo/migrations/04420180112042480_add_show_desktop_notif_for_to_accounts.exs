defmodule UcxUcc.Repo.Migrations.AddShowDesktopNofifToAccounts do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      add :show_desktop_notifications_for, :string, default: "system_default"
    end
  end

  def down do
    alter table(:accounts) do
      remove :show_desktop_notifications_for
    end
  end
end
