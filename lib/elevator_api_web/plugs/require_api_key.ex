defmodule ElevatorApiWeb.Plugs.RequireApiKey do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected_key = Application.get_env(:elevator_api, :api_key)

    case get_req_header(conn, "x-api-key") do
      [given_key] when is_binary(given_key) and is_binary(expected_key) ->
        if Plug.Crypto.secure_compare(given_key, expected_key) do
          conn
        else
          unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{errors: [%{message: "unauthorized"}]}))
    |> halt()
  end
end
