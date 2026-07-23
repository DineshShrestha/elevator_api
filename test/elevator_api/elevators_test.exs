defmodule ElevatorApi.ElevatorsTest do
  # Uses the global ElevatorApi.Elevators.Registry, so this must not run
  # concurrently with other tests that touch that registry.
  use ElevatorApi.DataCase, async: false

  alias ElevatorApi.Buildings
  alias ElevatorApi.Customers
  alias ElevatorApi.Elevators

  defp create_customer! do
    {:ok, customer, _api_key} = Customers.create_customer("Acme Corp")
    customer
  end

  defp create_building!(customer, attrs \\ %{}) do
    {:ok, building} =
      Buildings.create_building(
        customer.id,
        Map.merge(%{name: "Office Tower", min_floor: 1, max_floor: 20}, attrs)
      )

    building
  end

  # Elevators.create_elevator/1 starts its GenServer under the application's
  # global ElevatorSupervisor, not ExUnit's test-scoped supervisor, so it
  # isn't cleaned up automatically like start_supervised! children are.
  defp create_elevator!(building, attrs \\ %{}) do
    {:ok, elevator} =
      Elevators.create_elevator(
        Map.merge(%{building_id: building.id, min_floor: 1, max_floor: 10}, attrs)
      )

    on_exit(fn -> ElevatorApi.Elevators.ElevatorSupervisor.stop_elevator(elevator.id) end)

    elevator
  end

  test "assigns a hall call to the nearest suitable elevator" do
    customer = create_customer!()
    building = create_building!(customer)
    far = create_elevator!(building, %{min_floor: 1, max_floor: 20})
    near = create_elevator!(building, %{min_floor: 8, max_floor: 20})

    {:ok, assigned_state} = Elevators.request_hall_call(customer.id, building.id, 9, :up)

    assert assigned_state.id == near.id
    refute assigned_state.id == far.id
    assert MapSet.member?(assigned_state.pending_up, 9)
  end

  test "does not assign a hall call to an elevator in a different building" do
    customer = create_customer!()
    building_a = create_building!(customer)
    building_b = create_building!(customer)
    create_elevator!(building_a)

    assert Elevators.request_hall_call(customer.id, building_b.id, 3, :up) ==
             {:error, :no_available_elevator}
  end

  test "returns building_not_found when the building belongs to a different customer" do
    owner = create_customer!()
    other = create_customer!()
    building = create_building!(owner)
    create_elevator!(building)

    assert Elevators.request_hall_call(other.id, building.id, 3, :up) ==
             {:error, :building_not_found}
  end

  test "returns an error when no elevator is running in the building" do
    customer = create_customer!()
    building = create_building!(customer)

    assert Elevators.request_hall_call(customer.id, building.id, 3, :up) ==
             {:error, :no_available_elevator}
  end

  test "returns an error for an unknown building" do
    customer = create_customer!()
    assert Elevators.request_hall_call(customer.id, -1, 3, :up) == {:error, :building_not_found}
  end

  test "returns an error when the floor is outside the building's range" do
    customer = create_customer!()
    building = create_building!(customer, %{min_floor: 1, max_floor: 10})
    create_elevator!(building)

    assert Elevators.request_hall_call(customer.id, building.id, 50, :up) ==
             {:error, :floor_out_of_range}
  end

  test "create_elevator/1 persists the row and starts a GenServer" do
    customer = create_customer!()
    elevator = create_elevator!(create_building!(customer))

    assert {:ok, state} = Elevators.get_elevator_state(elevator.id)
    assert state.current_floor == 1
  end

  test "update_elevator/2 restarts the GenServer with the new floor range" do
    customer = create_customer!()
    elevator = create_elevator!(create_building!(customer))

    assert {:ok, updated} = Elevators.update_elevator(elevator, %{min_floor: 5, max_floor: 15})
    assert {:ok, state} = Elevators.get_elevator_state(updated.id)
    assert state.min_floor == 5
    assert state.current_floor == 5
  end

  test "delete_elevator/1 stops the GenServer and removes the row" do
    customer = create_customer!()
    elevator = create_elevator!(create_building!(customer))

    assert {:ok, _deleted} = Elevators.delete_elevator(elevator)
    assert Elevators.get_elevator_state(elevator.id) == {:error, :not_found}
    assert Elevators.get_elevator(elevator.id, customer.id) == {:error, :not_found}
  end

  test "get_elevator/2 returns not_found for another customer's elevator" do
    owner = create_customer!()
    other = create_customer!()
    elevator = create_elevator!(create_building!(owner))

    assert Elevators.get_elevator(elevator.id, other.id) == {:error, :not_found}
  end
end
