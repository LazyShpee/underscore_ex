defmodule UnderscoreEx.Router.Api do
  use Plug.Router

  plug(:need_auth)
  plug(:match)
  plug(:dispatch)

  def need_auth(conn, _opts \\ []) do
    with %UnderscoreEx.Schema.Cerealai.User{} <- conn.assigns[:user] do
      conn
    else
      _ ->
        conn
        |> send_resp(401, "Fuck off.")
        |> halt()
    end
  end

  forward("/caca", to: UnderscoreEx.Router.Api.Caca)

  get "/test" do
    send_resp(conn, 200, "OK")
  end

  get "/" do
    send_resp(conn, 200, "Welcome GET [api]")
  end

  match _ do
    send_resp(conn, 404, "Oops! [api]")
  end
end
