defmodule OneChat.InvitationService do
  use OneChat.Shared, :service
  alias InfinityOne.Coherence.Invitation
  alias InfinityOne.Accounts.User
  import Ecto.Changeset
  import Coherence.Controller

  def create_and_send(email, name \\ nil) do
    name = if name, do: name, else: String.split(email, "@") |> hd
    invitation_params = %{email: email, name: name}

    cs = Invitation.changeset(%Invitation{}, invitation_params)
    case Repo.one from u in User, where: u.email == ^email do
      nil ->
        token = random_string 48
        url = InfinityOneWeb.Router.Helpers.invitation_url(InfinityOneWeb.Endpoint, :edit, token)
        cs = put_change(cs, :token, token)
        case Repo.insert cs do
          {:ok, invitation} ->
            send_user_email :invitation, invitation, url
            {:ok, invitation}
          {:error, changeset} ->
            changeset = case Repo.one from i in Invitation, where: i.email == ^email do
              nil ->
                changeset
              _invitation ->
                add_error(changeset, :email, ~g"Invitation already sent.")
            end
            {:error, changeset}
        end
      _ ->
        {:error, add_error(cs, :email, ~g"User already has an account!")}
    end
  end

  def resend(id) do
    case Repo.get(Invitation, id) do
      nil ->
        {:error, ~g"Cound not find the Invitation"}
      invitation ->
        send_user_email :invitation, invitation,
          InfinityOneWeb.Router.Helpers.invitation_url(InfinityOneWeb.Endpoint,
          :edit, invitation.token)
        {:ok, ~g"Invitation resent."}
    end
  end
end
