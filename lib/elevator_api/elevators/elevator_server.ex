defmodule ElevatorApi.Elevators.ElevatorServer do
  use GenServer

  import Ecto.Query

  alias ElevatorApi.Elevators.{CarRequest, Elevator, ElevatorState, HallRequest, Scheduler}
  alias ElevatorApi.Repo

  @tick_interval_ms Application.compile_env(:elevator_api, :elevator_tick_interval_ms, 1000)

  def start_link(%{id: id, min_floor: min_floor, max_floor: max_floor} = attrs) do
    GenServer.start_link(__MODULE__, {id, min_floor, max_floor, attrs[:state]},
      name: via_tuple(id)
    )
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
  def init({id, min_floor, max_floor, persisted_state}) do
    state =
      case persisted_state do
        nil -> ElevatorState.new(id, min_floor, max_floor)
        map -> ElevatorState.from_map(map)
      end

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add_hall_request, %HallRequest{direction: :up, floor: floor}}, _from, state) do
    new_state = %{state | pending_up: MapSet.put(state.pending_up, floor)}
    maybe_start_ticking(state, new_state)
    persist(new_state)
    {:reply, new_state, new_state}
  end

  def handle_call({:add_hall_request, %HallRequest{direction: :down, floor: floor}}, _from, state) do
    new_state = %{state | pending_down: MapSet.put(state.pending_down, floor)}
    maybe_start_ticking(state, new_state)
    persist(new_state)
    {:reply, new_state, new_state}
  end

  def handle_call({:add_car_request, %CarRequest{floor: floor}}, _from, state) do
    new_state = %{state | car_requests: MapSet.put(state.car_requests, floor)}
    maybe_start_ticking(state, new_state)
    persist(new_state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = Scheduler.step(state)
    persist(new_state)

    if Scheduler.has_work?(new_state) do
      Process.send_after(self(), :tick, @tick_interval_ms)
    end

    {:noreply, new_state}
  end

  defp maybe_start_ticking(old_state, new_state) do
    if not Scheduler.has_work?(old_state) and Scheduler.has_work?(new_state) do
      Process.send_after(self(), :tick, @tick_interval_ms)
    end
  end

  # Write-through persistence so a crash/restart recovers the live state
  # instead of resetting every elevator to idle at its min floor. A no-op
  # (matches zero rows) for elevators not backed by a DB row, e.g. in tests.
  defp persist(state) do
    from(e in Elevator, where: e.id == ^state.id)
    |> Repo.update_all(set: [state: ElevatorState.to_map(state)])

    :ok
  end
end
