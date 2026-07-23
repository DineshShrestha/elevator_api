defmodule ElevatorApi.Elevators.HallRequest do
  @enforce_keys [:floor, :direction]
  defstruct [:floor, :direction]

  def new(floor, direction) when direction in [:up, :down] and is_integer(floor) do
    %__MODULE__{floor: floor, direction: direction}
  end
end
