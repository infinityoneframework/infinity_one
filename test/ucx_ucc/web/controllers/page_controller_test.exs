defmodule UcxUcc.Web.PageControllerTest do
  use UcxUcc.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
