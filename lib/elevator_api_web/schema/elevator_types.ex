defmodule ElevatorApiWeb.Schema.ElevatorTypes do
  use Absinthe.Schema.Notation

  enum :elevator_mode do
    value(:normal)
    value(:maintenance)
    value(:emergency)
    value(:out_of_service)
  end

  enum :elevator_direction do
    value(:up)
    value(:down)
    value(:idle)
  end

  enum :elevator_movement_state do
    value(:stopped)
    value(:moving)
  end

  enum :elevator_door_state do
    value(:open)
    value(:closed)
  end

  enum :hall_direction do
    value(:up)
    value(:down)
  end

  object :elevator_state do
    field :id, :id
    field :min_floor, :integer
    field :max_floor, :integer
    field :current_floor, :integer
    field :direction, :elevator_direction
    field :movement_state, :elevator_movement_state
    field :door_state, :elevator_door_state
    field :mode, :elevator_mode

    field :pending_up, list_of(:integer) do
      resolve(fn state, _args, _resolution -> {:ok, MapSet.to_list(state.pending_up)} end)
    end

    field :pending_down, list_of(:integer) do
      resolve(fn state, _args, _resolution -> {:ok, MapSet.to_list(state.pending_down)} end)
    end

    field :car_requests, list_of(:integer) do
      resolve(fn state, _args, _resolution -> {:ok, MapSet.to_list(state.car_requests)} end)
    end

    field :current_target, :integer
  end
end
