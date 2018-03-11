defmodule InfinityOne.Settings.Schema.Accounts do
  use OneSettings.Settings.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "settings_accounts" do
    field :allow_users_delete_own_account, :boolean, default: false
    field :allow_user_profile_change, :boolean, default: true
    field :allow_username_change, :boolean, default: true
    field :allow_email_change, :boolean, default: true
    field :allow_password_change, :boolean, default: true
    field :login_extiration_in_days, :integer, default: 90

    field :require_name_for_signup, :boolean, default: true
    field :require_password_confirmation, :boolean, default: true
    field :require_email_verificaton, :boolean, default: false
    field :require_account_confirmation, :boolean, default: true
    field :manually_approve_new_users, :boolean, default: false
    field :blocked_username_list, :string, default: ""
    field :registraton_form, :string, default: "Public"
    field :password_reset, :boolean, default: true
    field :registration_form_secret_url, :string,  default: "a4c45Yz15eB99c3R7fE3b50a"
    field :allow_remember_me, :boolean, default: true
  end

  @fields [
    :allow_users_delete_own_account, :allow_user_profile_change,
    :allow_username_change, :allow_email_change, :allow_password_change,
    :login_extiration_in_days, :require_name_for_signup,
    :require_password_confirmation, :require_email_verificaton,
    :manually_approve_new_users, :blocked_username_list,
    :registraton_form, :password_reset, :registration_form_secret_url,
    :require_account_confirmation, :allow_remember_me
  ]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required(@fields -- [:blocked_username_list])
  end
end

