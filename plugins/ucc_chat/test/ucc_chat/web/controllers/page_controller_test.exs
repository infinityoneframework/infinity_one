defmodule UccChatWeb.PageControllerTest do
  use UccChatWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Username"
  end
end
