defmodule ElevatorApi.Elevators.ElevatorServer do
  use GenServer

  alias ElevatorApi.Elevators.{CarRequest, ElevatorState, HallRequest}

  def start_link(%{id: id, min_floor: min_floor, max_floor: max_floor}) do
    GenServer.start_link(__MODULE__, {id, min_floor, max_floor}, name: via_tuple(id))
  end

  def via_tuple(id) do
    {:via, Registry, {ElevatorApi.Elevators.Registry, id}}
  end

  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  def add_hall_request(id, %HallRequest{} = hall_request) do
    GenServer.call(via_tuple(id), {:add_hall_request, hall_request})
  end

  def add_car_request(id, %CarRequest{} = car_request) do
    GenServer.call(via_tuple(id), {:add_car_request, car_request})
  end

  @impl true
  def init({id, min_floor, max_floor}) do
    {:ok, ElevatorState.new(id, min_floor, max_floor)}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add_hall_request, %HallRequest{direction: :up, floor: floor}}, _from, state) do
    state = %{state | pending_up: MapSet.put(state.pending_up, floor)}
    {:reply, state, state}
  end

  def handle_call({:add_hall_request, %HallRequest{direction: :down, floor: floor}}, _from, state) do
    state = %{state | pending_down: MapSet.put(state.pending_down, floor)}
    {:reply, state, state}
  end

  def handle_call({:add_car_request, %CarRequest{floor: floor}}, _from, state) do
    state = %{state | car_requests: MapSet.put(state.car_requests, floor)}
    {:reply, state, state}
  end
end
