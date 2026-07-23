defmodule ElevatorApiWeb.Plugs.RequireApiKey do
  import Plug.Conn

  alias ElevatorApi.Customers

  def init(opts), do: opts

  def call(conn, _opts) do
    with [key] <- get_req_header(conn, "x-api-key"),
         {:ok, customer} <- Customers.get_customer_by_api_key(key) do
      conn
      |> assign(:current_customer, customer)
      |> Absinthe.Plug.put_options(context: %{current_customer: customer})
    else
      _ -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{errors: [%{message: "unauthorized"}]}))
    |> halt()
  end
end
