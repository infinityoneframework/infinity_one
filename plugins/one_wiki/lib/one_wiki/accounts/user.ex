defmodule OneWiki.Accounts.User do
  use Unbrella.Plugin.Schema, InfinityOne.Accounts.User

  alias OneWiki.Schema.{Page, Subscription}

  require Logger

  Code.ensure_compiled(Subscription)
  Code.ensure_compiled(Page)

  extend_schema InfinityOne.Accounts.User do
    many_to_many :pages, Page, join_through: Subscription
  end

  def changeset(changeset, _pararm) do
    changeset
  end
end
