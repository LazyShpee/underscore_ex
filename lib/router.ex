defmodule UnderscoreEx.Router do
  use Plug.Router

  # plug(CORSPlug, headers: ["*"])
  plug(Plug.Logger, log: :info)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:cerealai_auth)
  plug(:match)
  plug(:dispatch)

  def cerealai_auth(conn, _opts) do
    conn = conn |> fetch_query_params()
    auth = conn |> get_req_header("authorization") |> Enum.at(0)

    token =
      cond do
        is_binary(conn.params["token"]) == true ->
          conn.params["token"]

        is_binary(auth) == true ->
          auth

        true ->
          nil
      end

    # import Ecto.Query
    alias UnderscoreEx.Repo
    alias UnderscoreEx.Schema.Cerealai.User

    conn =
      with true <- is_binary(token),
           %User{} = user <- User |> Repo.get_by(token: token) do
        conn |> assign(:user, user)
      else
        _ -> conn
      end

    conn
  end

  forward("/api", to: UnderscoreEx.Router.Api)

  match _ do
    send_resp(conn, 404, ":(")
  end
end
