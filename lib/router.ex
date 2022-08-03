defmodule UnderscoreEx.Router do
  use Plug.Router

  # plug(CORSPlug, headers: ["*"])
  plug(Plug.Logger, log: :info)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome GET")
  end

  post "/" do
    send_resp(conn, 200, "Welcome POST")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
