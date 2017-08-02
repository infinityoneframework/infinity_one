defmodule UcxUccWeb.PageControllerTest do
  use UcxUccWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Username"
  end
end
