defmodule InfinityOne.Repo.Migrations.CreateAccountsSettings do
  use Ecto.Migration

  def up do
    create table(:settings_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :allow_users_delete_own_account, :boolean, default: false
      add :allow_user_profile_change, :boolean, default: true
      add :allow_username_change, :boolean, default: true
      add :allow_email_change, :boolean, default: true
      add :allow_password_change, :boolean, default: true
      add :login_extiration_in_days, :integer, default: 90
      add :require_name_for_signup, :boolean, default: true
      add :require_password_confirmation, :boolean, default: true
      add :require_email_verificaton, :boolean, default: false
      add :manually_approve_new_users, :boolean, default: false
      add :blocked_username_list, :string, default: ""
      add :registraton_form, :string, default: "Public"
      add :password_reset, :boolean, default: true
      add :registration_form_secret_url, :string,  default: "a4c45Yz15eB99c3R7fE3b50a"
      add :require_account_confirmation, :boolean, default: true
      add :allow_remember_me, :boolean, default: true
    end
  end

  def down do
    drop table(:settings_accounts)
  end
end
