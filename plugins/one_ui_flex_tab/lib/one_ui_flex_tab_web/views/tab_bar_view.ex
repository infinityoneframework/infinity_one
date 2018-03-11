defmodule OneUiFlexTabWeb.TabBarView do
  @moduledoc """
  View helpers for the TabBar templates.
  """
  use OneUiFlexTabWeb, :view

  alias InfinityOne.TabBar

  @doc """
  Test if a group is visible for a given tag.

  ## Examples

      iex> tab = %{groups: [:one, :two]}
      iex> OneUiFlexTabWeb.TabBarView.visible? tab, :one
      true
      iex> OneUiFlexTabWeb.TabBarView.visible? tab, :three
      false
  """
  # @spec visible?(InfinityOne.TabBar.Tab.t, atom | list) :: boolean
  def visible?(tab, groups) when is_list(groups) do
    Enum.reduce groups, false, fn group, acc ->
      acc || visible?(tab, group)
    end
  end

  def visible?(tab, group) do
    group in Map.get(tab, :groups, [])
  end

  def buttons do
    TabBar.get_buttons
  end

end
