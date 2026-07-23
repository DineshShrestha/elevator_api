defmodule ElevatorApiWeb.GraphqlTest do
  # Creating an elevator starts a GenServer in the global Registry, so this
  # must not run concurrently with other tests that touch it.
  use ElevatorApiWeb.ConnCase, async: false

  @api_key Application.compile_env(:elevator_api, :api_key)

  defp graphql(conn, query, variables \\ %{}) do
    conn
    |> post("/graphql", %{"query" => query, "variables" => variables})
    |> json_response(200)
  end

  test "rejects requests without an API key", %{conn: conn} do
    conn = post(conn, "/graphql", %{"query" => "{ health }"})

    assert conn.status == 401
  end

  test "rejects requests with the wrong API key", %{conn: conn} do
    conn =
      conn
      |> put_req_header("x-api-key", "wrong-key")
      |> post("/graphql", %{"query" => "{ health }"})

    assert conn.status == 401
  end

  test "allows requests with the correct API key", %{conn: conn} do
    conn = put_req_header(conn, "x-api-key", @api_key)

    assert %{"data" => %{"health" => "Elevator API is running"}} = graphql(conn, "{ health }")
  end

  test "creates a building and elevator, lists it, then deletes it", %{conn: conn} do
    conn = put_req_header(conn, "x-api-key", @api_key)

    create_building = """
    mutation {
      createBuilding(input: {name: "Office Tower", minFloor: 1, maxFloor: 10}) {
        id
      }
    }
    """

    %{"data" => %{"createBuilding" => %{"id" => building_id}}} = graphql(conn, create_building)

    create_elevator = """
    mutation {
      createElevator(input: {buildingId: "#{building_id}", minFloor: 1, maxFloor: 10}) {
        id
        currentFloor
      }
    }
    """

    %{"data" => %{"createElevator" => %{"id" => elevator_id}}} = graphql(conn, create_elevator)

    %{"data" => %{"elevators" => elevators}} = graphql(conn, "{ elevators { id } }")
    assert Enum.any?(elevators, &(&1["id"] == elevator_id))

    delete_elevator = """
    mutation {
      deleteElevator(id: "#{elevator_id}") {
        id
      }
    }
    """

    assert %{"data" => %{"deleteElevator" => %{"id" => ^elevator_id}}} =
             graphql(conn, delete_elevator)

    %{"data" => %{"elevators" => elevators_after}} = graphql(conn, "{ elevators { id } }")
    refute Enum.any?(elevators_after, &(&1["id"] == elevator_id))
  end
end
