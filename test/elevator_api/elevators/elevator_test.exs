defmodule ElevatorApi.Elevators.ElevatorTest do
  use ElevatorApi.DataCase, async: true

  alias ElevatorApi.Buildings.Building
  alias ElevatorApi.Elevators.Elevator

  setup do
    building =
      Repo.insert!(%Building{
        name: "Office Tower",
        min_floor: 1,
        max_floor: 10
      })

    %{building: building}
  end

  test "changeset is valid with correct data", %{building: building} do
    attrs = %{building_id: building.id, min_floor: 1, max_floor: 10}

    changeset = Elevator.changeset(%Elevator{}, attrs)

    assert changeset.valid?
  end

  test "changeset requires building_id and floor range" do
    changeset = Elevator.changeset(%Elevator{}, %{})

    refute changeset.valid?

    assert errors_on(changeset) == %{
             building_id: ["can't be blank"],
             min_floor: ["can't be blank"],
             max_floor: ["can't be blank"]
           }
  end

  test "changeset rejects an invalid floor range", %{building: building} do
    attrs = %{building_id: building.id, min_floor: 10, max_floor: 5}

    changeset = Elevator.changeset(%Elevator{}, attrs)

    refute changeset.valid?

    assert "must be lower than max floor" in errors_on(changeset).min_floor
  end
end
