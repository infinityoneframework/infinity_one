defmodule UccAdmin.Web.PageControllerTest do
  use UccAdmin.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Username"
  end
end
