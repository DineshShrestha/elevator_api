defmodule ElevatorApi.ElevatorsTest do
  # Uses the global ElevatorApi.Elevators.Registry, so this must not run
  # concurrently with other tests that touch that registry.
  use ElevatorApi.DataCase, async: false

  alias ElevatorApi.Buildings
  alias ElevatorApi.Elevators
  alias ElevatorApi.Elevators.ElevatorServer

  defp start_elevator(id, min_floor, max_floor) do
    start_supervised!(
      {ElevatorServer, %{id: id, min_floor: min_floor, max_floor: max_floor}},
      id: {ElevatorServer, id}
    )
  end

  defp create_building! do
    {:ok, building} =
      Buildings.create_building(%{name: "Office Tower", min_floor: 1, max_floor: 20})

    building
  end

  # Elevators.create_elevator/1 starts its GenServer under the application's
  # global ElevatorSupervisor, not ExUnit's test-scoped supervisor, so it
  # isn't cleaned up automatically like start_supervised! children are.
  defp create_elevator!(building) do
    {:ok, elevator} =
      Elevators.create_elevator(%{building_id: building.id, min_floor: 1, max_floor: 10})

    on_exit(fn -> ElevatorApi.Elevators.ElevatorSupervisor.stop_elevator(elevator.id) end)

    elevator
  end

  test "assigns a hall call to the nearest suitable elevator" do
    far = System.unique_integer([:positive])
    near = System.unique_integer([:positive])

    start_elevator(far, 1, 20)
    start_elevator(near, 8, 20)

    {:ok, assigned_state} = Elevators.request_hall_call(9, :up)

    assert assigned_state.id == near
    assert MapSet.member?(assigned_state.pending_up, 9)
  end

  test "returns an error when no elevator is running" do
    assert Elevators.request_hall_call(3, :up) == {:error, :no_available_elevator}
  end

  test "create_elevator/1 persists the row and starts a GenServer" do
    elevator = create_elevator!(create_building!())

    assert {:ok, state} = Elevators.get_elevator_state(elevator.id)
    assert state.current_floor == 1
  end

  test "update_elevator/2 restarts the GenServer with the new floor range" do
    elevator = create_elevator!(create_building!())

    assert {:ok, updated} = Elevators.update_elevator(elevator, %{min_floor: 5, max_floor: 15})
    assert {:ok, state} = Elevators.get_elevator_state(updated.id)
    assert state.min_floor == 5
    assert state.current_floor == 5
  end

  test "delete_elevator/1 stops the GenServer and removes the row" do
    elevator = create_elevator!(create_building!())

    assert {:ok, _deleted} = Elevators.delete_elevator(elevator)
    assert Elevators.get_elevator_state(elevator.id) == {:error, :not_found}
    assert Elevators.get_elevator(elevator.id) == {:error, :not_found}
  end
end
