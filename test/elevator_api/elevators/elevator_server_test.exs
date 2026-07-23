defmodule ElevatorApi.Elevators.ElevatorServerTest do
  # ElevatorServer persists to the DB from its own process (not the test
  # process), and registers in the global ElevatorApi.Elevators.Registry, so
  # this must run with a shared sandbox connection and not concurrently with
  # other tests that touch that registry.
  use ElevatorApi.DataCase, async: false

  alias ElevatorApi.Buildings
  alias ElevatorApi.Customers
  alias ElevatorApi.Elevators
  alias ElevatorApi.Elevators.{CarRequest, ElevatorServer, ElevatorSupervisor, HallRequest}

  setup do
    id = System.unique_integer([:positive])
    start_supervised!({ElevatorServer, %{id: id, min_floor: 1, max_floor: 10}})
    %{id: id}
  end

  defp create_persisted_elevator! do
    {:ok, customer, _api_key} = Customers.create_customer("Acme Corp")

    {:ok, building} =
      Buildings.create_building(customer.id, %{name: "Office Tower", min_floor: 1, max_floor: 10})

    {:ok, elevator} =
      Elevators.create_elevator(%{building_id: building.id, min_floor: 1, max_floor: 10})

    on_exit(fn -> ElevatorSupervisor.stop_elevator(elevator.id) end)

    %{elevator: elevator, customer: customer}
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

  test "ticks toward and arrives at a requested floor", %{id: id} do
    # starts at floor 1; reaching floor 2 takes: pick target, move, arrive
    ElevatorServer.add_hall_request(id, HallRequest.new(2, :up))
    pid = GenServer.whereis(ElevatorServer.via_tuple(id))

    send(pid, :tick)
    send(pid, :tick)
    send(pid, :tick)
    state = ElevatorServer.get_state(id)

    assert state.current_floor == 2
    assert state.door_state == :open
    assert MapSet.size(state.pending_up) == 0
  end

  test "stops ticking once idle again", %{id: id} do
    ElevatorServer.add_hall_request(id, HallRequest.new(2, :up))
    pid = GenServer.whereis(ElevatorServer.via_tuple(id))

    # pick target, move, arrive (opens door), close door
    send(pid, :tick)
    send(pid, :tick)
    send(pid, :tick)
    send(pid, :tick)
    state = ElevatorServer.get_state(id)

    assert state.current_floor == 2
    assert state.door_state == :closed
    assert state.current_target == nil
  end

  test "recovers in-flight state after a crash/restart instead of resetting" do
    %{elevator: elevator, customer: customer} = create_persisted_elevator!()

    ElevatorServer.add_hall_request(elevator.id, HallRequest.new(3, :up))
    pid = GenServer.whereis(ElevatorServer.via_tuple(elevator.id))

    # pick target, then move one floor (not yet arrived)
    send(pid, :tick)
    send(pid, :tick)

    mid_transit_state = ElevatorServer.get_state(elevator.id)
    assert mid_transit_state.current_floor == 2
    assert mid_transit_state.current_target == 3

    # simulate a crash: stop the GenServer directly, bypassing delete_elevator
    ElevatorSupervisor.stop_elevator(elevator.id)
    assert Elevators.get_elevator_state(elevator.id) == {:error, :not_found}

    {:ok, persisted} = Elevators.get_elevator(elevator.id, customer.id)

    {:ok, _pid} =
      ElevatorSupervisor.start_elevator(%{
        id: persisted.id,
        min_floor: persisted.min_floor,
        max_floor: persisted.max_floor,
        state: persisted.state
      })

    recovered_state = ElevatorServer.get_state(elevator.id)
    assert recovered_state.current_floor == 2
    assert recovered_state.current_target == 3
    assert recovered_state.direction == :up
    assert MapSet.member?(recovered_state.pending_up, 3)
  end
end
