defmodule ElevatorApi.Elevators.CarRequest do
  @enforce_keys [:floor]
  defstruct [:floor]

  def new(floor) when is_integer(floor) do
    %__MODULE__{floor: floor}
  end
end
