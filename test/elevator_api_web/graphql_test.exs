defmodule ElevatorApiWeb.GraphqlTest do
  # Creating an elevator starts a GenServer in the global Registry, so this
  # must not run concurrently with other tests that touch it.
  use ElevatorApiWeb.ConnCase, async: false

  alias ElevatorApi.Customers

  defp with_api_key(conn) do
    {:ok, customer, api_key} = Customers.create_customer("Acme Corp")
    {put_req_header(conn, "x-api-key", api_key), customer}
  end

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

  test "allows requests with a valid API key", %{conn: conn} do
    {conn, _customer} = with_api_key(conn)

    assert %{"data" => %{"health" => "Elevator API is running"}} = graphql(conn, "{ health }")
  end

  test "creates a building and elevator, lists it, then deletes it", %{conn: conn} do
    {conn, _customer} = with_api_key(conn)

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

  test "one customer cannot see or control another customer's buildings/elevators", %{
    conn: conn
  } do
    {conn_a, _customer_a} = with_api_key(conn)
    {conn_b, _customer_b} = with_api_key(conn)

    create_building = """
    mutation {
      createBuilding(input: {name: "Customer A Building", minFloor: 1, maxFloor: 10}) { id }
    }
    """

    %{"data" => %{"createBuilding" => %{"id" => building_id}}} = graphql(conn_a, create_building)

    create_elevator = """
    mutation {
      createElevator(input: {buildingId: "#{building_id}", minFloor: 1, maxFloor: 10}) { id }
    }
    """

    %{"data" => %{"createElevator" => %{"id" => elevator_id}}} = graphql(conn_a, create_elevator)

    # customer B's list queries don't include customer A's resources
    %{"data" => %{"buildings" => buildings_b}} = graphql(conn_b, "{ buildings { id } }")
    refute Enum.any?(buildings_b, &(&1["id"] == building_id))

    %{"data" => %{"elevators" => elevators_b}} = graphql(conn_b, "{ elevators { id } }")
    refute Enum.any?(elevators_b, &(&1["id"] == elevator_id))

    # customer B's direct-fetch queries return null, not customer A's data
    assert %{"data" => %{"building" => nil}} =
             graphql(conn_b, "{ building(id: \"#{building_id}\") { id } }")

    assert %{"data" => %{"elevator" => nil}} =
             graphql(conn_b, "{ elevator(id: \"#{elevator_id}\") { id } }")

    # customer B cannot update, delete, or request a hall call for them
    update_building = """
    mutation {
      updateBuilding(id: "#{building_id}", input: {name: "Hijacked", minFloor: 1, maxFloor: 10}) { id }
    }
    """

    assert %{"errors" => [%{"message" => "building not found"}]} =
             graphql(conn_b, update_building)

    delete_elevator = """
    mutation { deleteElevator(id: "#{elevator_id}") { id } }
    """

    assert %{"errors" => [%{"message" => "elevator not found"}]} =
             graphql(conn_b, delete_elevator)

    request_hall_call = """
    mutation { requestHallCall(buildingId: "#{building_id}", floor: 2, direction: UP) { id } }
    """

    assert %{"errors" => [%{"message" => "building not found"}]} =
             graphql(conn_b, request_hall_call)

    # meanwhile customer A can still access their own resources normally
    assert %{"data" => %{"building" => %{"id" => ^building_id}}} =
             graphql(conn_a, "{ building(id: \"#{building_id}\") { id } }")
  end
end
