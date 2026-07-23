defmodule ElevatorApi.Elevators.GroupController do
  @moduledoc """
  Assigns hall requests to the best available elevator.

  See notes/02_group_controller.md for the design this implements.
  """

  alias ElevatorApi.Elevators.HallRequest

  @unavailable_modes [:maintenance, :emergency, :out_of_service]
  @direction_penalty 1000

  def assign(states, %HallRequest{} = hall_request) do
    case Enum.filter(states, &eligible?/1) do
      [] ->
        {:error, :no_available_elevator}

      eligible ->
        {best, _score} =
          eligible
          |> Enum.map(fn state -> {state, score(state, hall_request)} end)
          |> Enum.min_by(fn {state, score} -> {score, state.id} end)

        {:ok, best.id}
    end
  end

  def eligible?(state) do
    state.mode not in @unavailable_modes
  end

  def score(state, %HallRequest{} = hall_request) do
    distance(state, hall_request) +
      direction_penalty(state, hall_request) +
      pending_stop_penalty(state)
  end

  defp distance(state, hall_request) do
    abs(hall_request.floor - state.current_floor)
  end

  defp direction_penalty(%{direction: :idle}, _hall_request), do: 0

  defp direction_penalty(%{direction: :up} = state, hall_request) do
    if hall_request.floor > state.current_floor and hall_request.direction == :up do
      0
    else
      @direction_penalty
    end
  end

  defp direction_penalty(%{direction: :down} = state, hall_request) do
    if hall_request.floor < state.current_floor and hall_request.direction == :down do
      0
    else
      @direction_penalty
    end
  end

  defp pending_stop_penalty(state) do
    MapSet.size(state.pending_up) +
      MapSet.size(state.pending_down) +
      MapSet.size(state.car_requests)
  end
end
