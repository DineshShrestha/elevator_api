defmodule ElevatorApi.Elevators.ElevatorStateTest do
  use ExUnit.Case, async: true

  alias ElevatorApi.Elevators.ElevatorState

  test "creates an elevator at its minimum floor" do
    state = ElevatorState.new("elevator-1", 1, 5)

    assert state.id == "elevator-1"
    assert state.min_floor == 1
    assert state.max_floor == 5
    assert state.current_floor == 1
    assert state.direction == :idle
    assert state.movement_state == :stopped
    assert state.door_state == :closed
    assert state.mode == :normal
    assert state.pending_up == MapSet.new()
    assert state.pending_down == MapSet.new()
    assert state.car_requests == MapSet.new()
    assert state.current_target == nil
  end

  test "starts at a basement floor when the minimum floor is negative" do
    state = ElevatorState.new("elevator-2", -2, 10)

    assert state.current_floor == -2
    assert state.min_floor == -2
    assert state.max_floor == 10
  end
end
