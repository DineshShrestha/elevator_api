defmodule ElevatorApiWeb.Resolvers.ElevatorResolver do
  alias ElevatorApi.Elevators

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
end
