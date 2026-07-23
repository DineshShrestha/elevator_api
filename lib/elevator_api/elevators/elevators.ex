defmodule ElevatorApi.Elevators do
  alias ElevatorApi.Repo

  alias ElevatorApi.Elevators.{
    Elevator,
    ElevatorServer,
    ElevatorSupervisor,
    GroupController,
    HallRequest
  }

  def start_all_from_db do
    Elevator
    |> Repo.all()
    |> Enum.each(fn elevator ->
      ElevatorSupervisor.start_elevator(%{
        id: elevator.id,
        min_floor: elevator.min_floor,
        max_floor: elevator.max_floor
      })
    end)
  end

  def list_elevator_states do
    Registry.select(ElevatorApi.Elevators.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.map(&ElevatorServer.get_state/1)
  end

  def get_elevator_state(id) do
    case Registry.lookup(ElevatorApi.Elevators.Registry, id) do
      [{_pid, _value}] -> {:ok, ElevatorServer.get_state(id)}
      [] -> {:error, :not_found}
    end
  end

  def request_hall_call(floor, direction) do
    hall_request = HallRequest.new(floor, direction)

    case GroupController.assign(list_elevator_states(), hall_request) do
      {:ok, elevator_id} ->
        {:ok, ElevatorServer.add_hall_request(elevator_id, hall_request)}

      {:error, :no_available_elevator} = error ->
        error
    end
  end
end
