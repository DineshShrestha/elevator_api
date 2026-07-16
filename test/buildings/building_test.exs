defmodule ElevatorApi.Buildings.BuildingTest do
  use ElevatorApi.DataCase, async: true

  alias ElevatorApi.Buildings.Building

  test "changeset is valid with correct data" do
    attrs = %{
      name: "Office Tower",
      address: "Main Street 10",
      min_floor: -1,
      max_floor: 10
    }

    changeset = Building.changeset(%Building{}, attrs)

    assert changeset.valid?
  end

  test "changeset requires name and floor range" do
    changeset = Building.changeset(%Building{}, %{})

    refute changeset.valid?

    assert errors_on(changeset) == %{
             name: ["can't be blank"],
             min_floor: ["can't be blank"],
             max_floor: ["can't be blank"]
           }
  end

  test "changeset rejects an invalid floor range" do
    attrs = %{
      name: "Office Tower",
      min_floor: 10,
      max_floor: 5
    }

    changeset = Building.changeset(%Building{}, attrs)

    refute changeset.valid?

    assert "must be lower than max floor" in errors_on(changeset).min_floor
  end
end
