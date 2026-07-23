defmodule ElevatorApi.ElevatorsTest do
  # Uses the global ElevatorApi.Elevators.Registry, so this must not run
  # concurrently with other tests that touch that registry.
  use ExUnit.Case, async: false

  alias ElevatorApi.Elevators
  alias ElevatorApi.Elevators.ElevatorServer

  defp start_elevator(id, min_floor, max_floor) do
    start_supervised!(
      {ElevatorServer, %{id: id, min_floor: min_floor, max_floor: max_floor}},
      id: {ElevatorServer, id}
    )
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
end
