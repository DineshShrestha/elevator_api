defmodule ElevatorApiWeb.Plugs.RequireApiKeyTest do
  use ElevatorApi.DataCase, async: true

  import Plug.Test
  import Plug.Conn

  alias ElevatorApi.Customers
  alias ElevatorApiWeb.Plugs.RequireApiKey

  test "halts with 401 when the header is missing" do
    conn = conn(:post, "/graphql") |> RequireApiKey.call([])

    assert conn.halted
    assert conn.status == 401
  end

  test "halts with 401 when the key is wrong" do
    conn =
      conn(:post, "/graphql")
      |> put_req_header("x-api-key", "wrong-key")
      |> RequireApiKey.call([])

    assert conn.halted
    assert conn.status == 401
  end

  test "passes through and assigns the customer when the key matches" do
    {:ok, customer, api_key} = Customers.create_customer("Acme Corp")

    conn =
      conn(:post, "/graphql")
      |> put_req_header("x-api-key", api_key)
      |> RequireApiKey.call([])

    refute conn.halted
    assert conn.assigns.current_customer.id == customer.id
    assert conn.private.absinthe.context.current_customer.id == customer.id
  end
end
