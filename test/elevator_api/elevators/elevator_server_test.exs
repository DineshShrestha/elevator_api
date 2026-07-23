defmodule ElevatorApi.Elevators.ElevatorServerTest do
  # Registers processes in the global ElevatorApi.Elevators.Registry, so this
  # must not run concurrently with other tests that touch that registry.
  use ExUnit.Case, async: false

  alias ElevatorApi.Elevators.{CarRequest, ElevatorServer, HallRequest}

  setup do
    id = System.unique_integer([:positive])
    start_supervised!({ElevatorServer, %{id: id, min_floor: 1, max_floor: 10}})
    %{id: id}
  end

  test "starts at its minimum floor", %{id: id} do
    state = ElevatorServer.get_state(id)

    assert state.id == id
    assert state.current_floor == 1
    assert state.direction == :idle
  end

  test "records an up hall request", %{id: id} do
    state = ElevatorServer.add_hall_request(id, HallRequest.new(6, :up))

    assert MapSet.member?(state.pending_up, 6)
    assert ElevatorServer.get_state(id).pending_up == MapSet.new([6])
  end

  test "records a down hall request", %{id: id} do
    state = ElevatorServer.add_hall_request(id, HallRequest.new(3, :down))

    assert MapSet.member?(state.pending_down, 3)
  end

  test "records a car request", %{id: id} do
    state = ElevatorServer.add_car_request(id, CarRequest.new(8))

    assert MapSet.member?(state.car_requests, 8)
  end
end
