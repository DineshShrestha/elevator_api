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
end
