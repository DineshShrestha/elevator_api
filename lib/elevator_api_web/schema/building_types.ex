defmodule ElevatorApiWeb.Schema.BuildingTypes do
  use Absinthe.Schema.Notation

  object :building do
    field :id, :id
    field :name, :string
    field :address, :string
    field :min_floor, :integer
    field :max_floor, :integer
  end

  input_object :building_input do
    field :name, non_null(:string)
    field :address, :string
    field :min_floor, non_null(:integer)
    field :max_floor, non_null(:integer)
  end
end
