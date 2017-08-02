defmodule UccUiFlexTabWeb.TabBarView do
  @moduledoc """
  View helpers for the TabBar templates.
  """
  use UccUiFlexTabWeb, :view

  alias UcxUcc.TabBar

  @doc """
  Test if a group is visible for a given tag.

  ## Examples

      iex> tab = %{groups: [:one, :two]}
      iex> UccUiFlexTabWeb.TabBarView.visible? tab, :one
      true
      iex> UccUiFlexTabWeb.TabBarView.visible? tab, :three
      false
  """
  @spec visible?(UcxUcc.TabBar.Tab.t, atom) :: boolean
  def visible?(tab, group) do
    group in Map.get(tab, :groups, [])
  end

  def buttons do
    TabBar.get_buttons
  end

end
