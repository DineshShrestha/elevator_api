defmodule ElevatorApi.Elevators do
  import Ecto.Query

  alias ElevatorApi.Buildings
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

  def request_hall_call(building_id, floor, direction) do
    with {:ok, building} <- Buildings.get_building(building_id),
         :ok <- validate_floor_in_range(floor, building) do
      hall_request = HallRequest.new(floor, direction)
      building_elevator_states = list_elevator_states_for_building(building_id)

      case GroupController.assign(building_elevator_states, hall_request) do
        {:ok, elevator_id} ->
          {:ok, ElevatorServer.add_hall_request(elevator_id, hall_request)}

        {:error, :no_available_elevator} = error ->
          error
      end
    else
      {:error, :not_found} -> {:error, :building_not_found}
      {:error, :floor_out_of_range} = error -> error
    end
  end

  defp validate_floor_in_range(floor, building) do
    if floor in building.min_floor..building.max_floor do
      :ok
    else
      {:error, :floor_out_of_range}
    end
  end

  defp list_elevator_states_for_building(building_id) do
    elevator_ids =
      from(e in Elevator, where: e.building_id == ^building_id, select: e.id)
      |> Repo.all()
      |> MapSet.new()

    list_elevator_states()
    |> Enum.filter(&MapSet.member?(elevator_ids, &1.id))
  end

  def get_elevator(id) do
    case Repo.get(Elevator, id) do
      nil -> {:error, :not_found}
      elevator -> {:ok, elevator}
    end
  end

  def create_elevator(attrs) do
    with {:ok, elevator} <- %Elevator{} |> Elevator.changeset(attrs) |> Repo.insert() do
      ElevatorSupervisor.start_elevator(%{
        id: elevator.id,
        min_floor: elevator.min_floor,
        max_floor: elevator.max_floor
      })

      {:ok, elevator}
    end
  end

  def update_elevator(%Elevator{} = elevator, attrs) do
    with {:ok, updated} <- elevator |> Elevator.changeset(attrs) |> Repo.update() do
      ElevatorSupervisor.stop_elevator(updated.id)

      ElevatorSupervisor.start_elevator(%{
        id: updated.id,
        min_floor: updated.min_floor,
        max_floor: updated.max_floor
      })

      {:ok, updated}
    end
  end

  def delete_elevator(%Elevator{} = elevator) do
    ElevatorSupervisor.stop_elevator(elevator.id)
    Repo.delete(elevator)
  end
end
