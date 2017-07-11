defmodule UccWebrtc.Web.PageControllerTest do
  use UccWebrtc.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Username"
  end
end
