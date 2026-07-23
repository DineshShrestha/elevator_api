defmodule ElevatorApiWeb.Resolvers.ElevatorResolver do
  alias ElevatorApi.Buildings
  alias ElevatorApi.Elevators
  alias ElevatorApiWeb.ChangesetErrors

  def list_elevators(_parent, _args, %{context: %{current_customer: customer}}) do
    {:ok, Elevators.list_elevator_states_for_customer(customer.id)}
  end

  def get_elevator(_parent, %{id: id}, %{context: %{current_customer: customer}}) do
    int_id = String.to_integer(id)

    with {:ok, _elevator} <- Elevators.get_elevator(int_id, customer.id),
         {:ok, state} <- Elevators.get_elevator_state(int_id) do
      {:ok, state}
    else
      {:error, :not_found} -> {:ok, nil}
    end
  end

  def request_hall_call(
        _parent,
        %{building_id: building_id, floor: floor, direction: direction},
        %{context: %{current_customer: customer}}
      ) do
    case Elevators.request_hall_call(customer.id, building_id, floor, direction) do
      {:ok, state} -> {:ok, state}
      {:error, :building_not_found} -> {:error, "building not found"}
      {:error, :floor_out_of_range} -> {:error, "floor is out of range for this building"}
      {:error, :no_available_elevator} -> {:error, "no available elevator"}
    end
  end

  def create_elevator(_parent, %{input: input}, %{context: %{current_customer: customer}}) do
    with {:ok, _building} <- Buildings.get_building(input.building_id, customer.id),
         {:ok, elevator} <- Elevators.create_elevator(input) do
      {:ok, state} = Elevators.get_elevator_state(elevator.id)
      {:ok, state}
    else
      {:error, :not_found} -> {:error, "building not found"}
      {:error, changeset} -> {:error, ChangesetErrors.to_message(changeset)}
    end
  end

  def update_elevator(_parent, %{id: id, input: input}, %{context: %{current_customer: customer}}) do
    with {:ok, elevator} <- Elevators.get_elevator(String.to_integer(id), customer.id),
         {:ok, _building} <- Buildings.get_building(input.building_id, customer.id),
         {:ok, updated} <- Elevators.update_elevator(elevator, input),
         {:ok, state} <- Elevators.get_elevator_state(updated.id) do
      {:ok, state}
    else
      {:error, :not_found} -> {:error, "not found"}
      {:error, changeset} -> {:error, ChangesetErrors.to_message(changeset)}
    end
  end

  def delete_elevator(_parent, %{id: id}, %{context: %{current_customer: customer}}) do
    int_id = String.to_integer(id)

    with {:ok, elevator} <- Elevators.get_elevator(int_id, customer.id),
         {:ok, state} <- Elevators.get_elevator_state(int_id),
         {:ok, _deleted} <- Elevators.delete_elevator(elevator) do
      {:ok, state}
    else
      {:error, :not_found} -> {:error, "elevator not found"}
    end
  end
end
