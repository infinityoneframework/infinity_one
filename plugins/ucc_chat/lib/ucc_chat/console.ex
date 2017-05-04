defmodule UccChat.Console do
  @moduledoc """
  Console commands

  ## List
  * ca
  * ftab
  """
  alias UccChat.UserAgent, as: CA
    # import Ecto.Query
  alias UccChat.{Subscription}
  alias UcxUcc.Repo


  @doc """
  Get UserAgent state
  """
  def ca, do: CA.get

  @doc """
  Get ftab state for a given user_id, channel_id
  """
  def ftab(user_id, channel_id), do: CA.get_ftab(user_id, channel_id)

  @doc """
  Clear all last_read subscription fields
  """
  def clear_last_read do
    Subscription
    |> Repo.update_all(set: [last_read: "", current_message: ""])
  end
end
