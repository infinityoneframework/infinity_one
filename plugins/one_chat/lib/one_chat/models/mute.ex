defmodule OneChat.Mute do
  @moduledoc """
  Track mute status for user and channel.

  When created, the associated user is muted in the given channel. Delete
  the record to unmute them.
  """
  use OneModel, schema: OneChat.Schema.Mute
  use InfinityOneWeb.Gettext

  alias OneChat.Channel

  @doc """
  Checks if the user is muted in the given channel.

  Returns true if the user is muted, false otherwise.
  """
  def user_muted?(channel_id, user_id) do
    !!get_by(channel_id: channel_id, user_id: user_id)
  end

  @doc """
  A prepare changes hook to check that we are not trying to mute in a direct channel.
  """
  def prepare_check_channel(%{action: :insert} = changeset) do
    if Channel.direct?(changeset.changes.channel_id) do
      Ecto.Changeset.add_error(changeset, :channel_id,
        ~g(can't be muted in a direct message channel))
    else
      changeset
    end
  end

  def prepare_check_channel(changeset) do
    changeset
  end

end
