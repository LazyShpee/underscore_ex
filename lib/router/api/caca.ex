defmodule UnderscoreEx.Router.Api.Caca do
  use Plug.Router

  plug(:fetch_caca_user)
  plug(:match)
  plug(:dispatch)

  def fetch_caca_user(conn, _opts \\ []) do
    alias UnderscoreEx.Repo
    alias UnderscoreEx.Schema.Cerealai.User
    alias UnderscoreEx.Schema.Caca

    with %User{} = user <- conn.assigns[:user],
         %Caca.User{} = cc_user <-
           Caca.User
           |> Repo.get_by(discord_id: user.discord_id)do
      conn |> assign(:caca_user, cc_user)
    else
      _ ->
        conn
        |> send_resp(401, "No caca user found")
        |> halt()
    end
  end

  post "/import" do
    alias UnderscoreEx.Repo
    alias UnderscoreEx.Schema.Caca.Time

    cc_user = conn.assigns[:caca_user]

    body =
      conn.body_params
      |> UnderscoreEx.Util.transform(fn
        date ->
          case DateTime.from_iso8601(date) do
            {:ok, dt, _} -> dt
            _ -> date
          end
      end)

    data =
      [t_start: "start", t_end: "end", label: "label"]
      |> Enum.map(fn {target, source} ->
        {target, body |> Map.get(source)}
      end)
      |> Map.new()
      |> Map.merge(%{
        t_upload: Timex.now(),
        imported: true,
        user_id: cc_user.id
      })

    %Time{}
    |> Time.changeset(data)
    |> Repo.insert()
    |> case do
      {:error, cs} ->
        conn |> send_resp(401, "Supplied data is invalid\n" <> inspect(cs.errors)) |> halt()

      {:ok, _} ->
        conn |> send_resp(200, "Caca inserted")
    end
  end

  match _ do
    send_resp(conn, 404, "Oops! [api]")
  end
end
