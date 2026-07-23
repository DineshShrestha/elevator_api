defmodule ElevatorApiWeb.Resolvers.ElevatorResolver do
  alias ElevatorApi.Elevators
  alias ElevatorApiWeb.ChangesetErrors

  def list_elevators(_parent, _args, _resolution) do
    {:ok, Elevators.list_elevator_states()}
  end

  def get_elevator(_parent, %{id: id}, _resolution) do
    case Elevators.get_elevator_state(String.to_integer(id)) do
      {:ok, state} -> {:ok, state}
      {:error, :not_found} -> {:ok, nil}
    end
  end

  def request_hall_call(_parent, %{floor: floor, direction: direction}, _resolution) do
    case Elevators.request_hall_call(floor, direction) do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  def create_elevator(_parent, %{input: input}, _resolution) do
    case Elevators.create_elevator(input) do
      {:ok, elevator} ->
        {:ok, state} = Elevators.get_elevator_state(elevator.id)
        {:ok, state}

      {:error, changeset} ->
        {:error, ChangesetErrors.to_message(changeset)}
    end
  end

  def update_elevator(_parent, %{id: id, input: input}, _resolution) do
    with {:ok, elevator} <- Elevators.get_elevator(String.to_integer(id)),
         {:ok, updated} <- Elevators.update_elevator(elevator, input),
         {:ok, state} <- Elevators.get_elevator_state(updated.id) do
      {:ok, state}
    else
      {:error, :not_found} -> {:error, "elevator not found"}
      {:error, changeset} -> {:error, ChangesetErrors.to_message(changeset)}
    end
  end

  def delete_elevator(_parent, %{id: id}, _resolution) do
    int_id = String.to_integer(id)

    with {:ok, elevator} <- Elevators.get_elevator(int_id),
         {:ok, state} <- Elevators.get_elevator_state(int_id),
         {:ok, _deleted} <- Elevators.delete_elevator(elevator) do
      {:ok, state}
    else
      {:error, :not_found} -> {:error, "elevator not found"}
    end
  end
end
