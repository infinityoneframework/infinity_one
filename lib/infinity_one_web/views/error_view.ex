defmodule InfinityOneWeb.ErrorView do
  use InfinityOneWeb, :view

  alias InfinityOne.Accounts

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def support_email do
    Accounts.get_first_admin_email()
  end
end
