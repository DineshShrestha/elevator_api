defmodule ElevatorApi.Buildings.Building do
  use Ecto.Schema
  import Ecto.Changeset

  schema "buildings" do
    field :name, :string
    field :address, :string
    field :min_floor, :integer
    field :max_floor, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(building, attrs) do
    building
    |> cast(attrs, [:name, :address, :min_floor, :max_floor])
    |> validate_required([:name, :min_floor, :max_floor])
    |> validate_floor_range()
    |> check_constraint(:min_floor, name: :valid_floor_range)
  end

  def validate_floor_range(changeset) do
    min_floor = get_field(changeset, :min_floor)
    max_floor = get_field(changeset, :max_floor)

    if is_integer(min_floor) and is_integer(max_floor) and min_floor >= max_floor do
      add_error(changeset, :min_floor, "must be lower than max floor")
    else
      changeset
    end
  end
end
