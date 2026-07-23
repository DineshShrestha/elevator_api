defmodule ElevatorApi.Elevators.Scheduler do
  @moduledoc """
  Advances an ElevatorState by one discrete simulation tick: moving one floor
  at a time toward its current target, opening/closing doors on arrival, and
  picking the next target once idle.

  Once `current_target` is set, the elevator finishes traveling there before
  re-scanning for a new target, even if a closer request arrives in the
  meantime — no mid-transit rerouting in this first version.
  """

  alias ElevatorApi.Elevators.ElevatorState

  def has_work?(%ElevatorState{} = state) do
    state.current_target != nil or
      state.door_state == :open or
      not Enum.empty?(state.pending_up) or
      not Enum.empty?(state.pending_down) or
      not Enum.empty?(state.car_requests)
  end

  def step(%ElevatorState{door_state: :open} = state) do
    %{state | door_state: :closed}
  end

  def step(%ElevatorState{current_target: nil} = state) do
    case next_target(state) do
      nil ->
        %{state | direction: :idle, movement_state: :stopped}

      {target, direction} ->
        %{state | current_target: target, direction: direction, movement_state: :moving}
    end
  end

  def step(%ElevatorState{current_floor: floor, current_target: floor} = state) do
    state
    |> clear_floor(floor)
    |> Map.put(:current_target, nil)
    |> Map.put(:door_state, :open)
    |> Map.put(:movement_state, :stopped)
  end

  def step(%ElevatorState{current_floor: floor, current_target: target} = state)
      when target > floor do
    %{state | current_floor: floor + 1, direction: :up, movement_state: :moving}
  end

  def step(%ElevatorState{current_floor: floor, current_target: target} = state)
      when target < floor do
    %{state | current_floor: floor - 1, direction: :down, movement_state: :moving}
  end

  defp clear_floor(state, floor) do
    %{
      state
      | pending_up: MapSet.delete(state.pending_up, floor),
        pending_down: MapSet.delete(state.pending_down, floor),
        car_requests: MapSet.delete(state.car_requests, floor)
    }
  end

  defp next_target(state) do
    pending =
      state.pending_up
      |> MapSet.union(state.pending_down)
      |> MapSet.union(state.car_requests)
      |> MapSet.to_list()

    case pending do
      [] -> nil
      _ -> pick_target(state, pending)
    end
  end

  defp pick_target(%{direction: :idle} = state, pending) do
    target = closest(pending, state.current_floor)

    direction =
      cond do
        target > state.current_floor -> :up
        target < state.current_floor -> :down
        true -> :idle
      end

    {target, direction}
  end

  defp pick_target(%{direction: :down} = state, pending) do
    scan(pending, state.current_floor, :down, :up)
  end

  defp pick_target(%{direction: :up} = state, pending) do
    scan(pending, state.current_floor, :up, :down)
  end

  defp scan(pending, current_floor, primary_direction, fallback_direction) do
    ahead = Enum.filter(pending, &ahead?(&1, current_floor, primary_direction))
    behind = Enum.filter(pending, &ahead?(&1, current_floor, fallback_direction))

    cond do
      ahead != [] -> {closest(ahead, current_floor), primary_direction}
      behind != [] -> {closest(behind, current_floor), fallback_direction}
      true -> {current_floor, :idle}
    end
  end

  defp ahead?(floor, current_floor, :up), do: floor > current_floor
  defp ahead?(floor, current_floor, :down), do: floor < current_floor

  defp closest(floors, current_floor) do
    Enum.min_by(floors, &abs(&1 - current_floor))
  end
end
