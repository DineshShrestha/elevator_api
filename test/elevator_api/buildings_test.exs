defmodule ElevatorApi.BuildingsTest do
  # delete_building/1 stops elevator GenServers in the global Registry, so
  # this must not run concurrently with other tests that touch it.
  use ElevatorApi.DataCase, async: false

  alias ElevatorApi.Buildings
  alias ElevatorApi.Elevators

  @valid_attrs %{name: "Office Tower", address: "Main Street 10", min_floor: 1, max_floor: 10}

  test "create_building/1 with valid attrs" do
    assert {:ok, building} = Buildings.create_building(@valid_attrs)
    assert building.name == "Office Tower"
  end

  test "create_building/1 with invalid attrs" do
    assert {:error, changeset} = Buildings.create_building(%{})
    refute changeset.valid?
  end

  test "get_building/1 returns not_found for a missing building" do
    assert Buildings.get_building(-1) == {:error, :not_found}
  end

  test "list_buildings/0 returns created buildings" do
    {:ok, building} = Buildings.create_building(@valid_attrs)

    assert building.id in Enum.map(Buildings.list_buildings(), & &1.id)
  end

  test "update_building/2 changes attributes" do
    {:ok, building} = Buildings.create_building(@valid_attrs)

    assert {:ok, updated} = Buildings.update_building(building, %{name: "New Name"})
    assert updated.name == "New Name"
  end

  test "delete_building/1 removes the building and stops its elevators" do
    {:ok, building} = Buildings.create_building(@valid_attrs)

    {:ok, elevator} =
      Elevators.create_elevator(%{building_id: building.id, min_floor: 1, max_floor: 10})

    assert {:ok, _state} = Elevators.get_elevator_state(elevator.id)

    assert {:ok, _deleted} = Buildings.delete_building(building)

    assert Buildings.get_building(building.id) == {:error, :not_found}
    assert Elevators.get_elevator_state(elevator.id) == {:error, :not_found}
  end
end
