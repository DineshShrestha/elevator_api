defmodule ElevatorApi.Elevators.ElevatorState do
  @enforce_keys [:id, :min_floor, :max_floor]

  defstruct [
    :id,
    :min_floor,
    :max_floor,
    current_floor: 1,
    direction: :idle,
    movement_state: :stopped,
    door_state: :closed,
    mode: :normal,
    pending_up: MapSet.new(),
    pending_down: MapSet.new(),
    car_requests: MapSet.new(),
    current_target: nil
  ]

  def new(id, min_floor, max_floor) do
    %__MODULE__{
      id: id,
      min_floor: min_floor,
      max_floor: max_floor,
      current_floor: min_floor
    }
  end

  @doc "Converts to a plain map for JSON persistence (see Elevator.state)."
  def to_map(%__MODULE__{} = state) do
    %{
      "id" => state.id,
      "min_floor" => state.min_floor,
      "max_floor" => state.max_floor,
      "current_floor" => state.current_floor,
      "direction" => to_string(state.direction),
      "movement_state" => to_string(state.movement_state),
      "door_state" => to_string(state.door_state),
      "mode" => to_string(state.mode),
      "pending_up" => MapSet.to_list(state.pending_up),
      "pending_down" => MapSet.to_list(state.pending_down),
      "car_requests" => MapSet.to_list(state.car_requests),
      "current_target" => state.current_target
    }
  end

  @doc "The reverse of to_map/1. Only ever called on our own previously-persisted data."
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      min_floor: map["min_floor"],
      max_floor: map["max_floor"],
      current_floor: map["current_floor"],
      direction: String.to_existing_atom(map["direction"]),
      movement_state: String.to_existing_atom(map["movement_state"]),
      door_state: String.to_existing_atom(map["door_state"]),
      mode: String.to_existing_atom(map["mode"]),
      pending_up: MapSet.new(map["pending_up"]),
      pending_down: MapSet.new(map["pending_down"]),
      car_requests: MapSet.new(map["car_requests"]),
      current_target: map["current_target"]
    }
  end
end
