defmodule ElevatorApiWeb.Plugs.RequireApiKeyTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias ElevatorApiWeb.Plugs.RequireApiKey

  @configured_key Application.compile_env(:elevator_api, :api_key)

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

  test "passes through when the key matches" do
    conn =
      conn(:post, "/graphql")
      |> put_req_header("x-api-key", @configured_key)
      |> RequireApiKey.call([])

    refute conn.halted
  end
end
