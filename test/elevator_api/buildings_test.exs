defmodule ElevatorApi.BuildingsTest do
  # delete_building/1 stops elevator GenServers in the global Registry, so
  # this must not run concurrently with other tests that touch it.
  use ElevatorApi.DataCase, async: false

  alias ElevatorApi.Buildings
  alias ElevatorApi.Customers
  alias ElevatorApi.Elevators

  @valid_attrs %{name: "Office Tower", address: "Main Street 10", min_floor: 1, max_floor: 10}

  defp create_customer! do
    {:ok, customer, _api_key} = Customers.create_customer("Acme Corp")
    customer
  end

  test "create_building/1 with valid attrs" do
    customer = create_customer!()

    assert {:ok, building} = Buildings.create_building(customer.id, @valid_attrs)
    assert building.name == "Office Tower"
    assert building.customer_id == customer.id
  end

  test "create_building/1 with invalid attrs" do
    customer = create_customer!()

    assert {:error, changeset} = Buildings.create_building(customer.id, %{})
    refute changeset.valid?
  end

  test "get_building/2 returns not_found for a missing building" do
    customer = create_customer!()

    assert Buildings.get_building(-1, customer.id) == {:error, :not_found}
  end

  test "get_building/2 returns not_found for another customer's building" do
    owner = create_customer!()
    other = create_customer!()

    {:ok, building} = Buildings.create_building(owner.id, @valid_attrs)

    assert Buildings.get_building(building.id, other.id) == {:error, :not_found}
  end

  test "list_buildings/1 returns only that customer's buildings" do
    customer = create_customer!()
    other = create_customer!()

    {:ok, building} = Buildings.create_building(customer.id, @valid_attrs)
    {:ok, _other_building} = Buildings.create_building(other.id, @valid_attrs)

    ids = Enum.map(Buildings.list_buildings(customer.id), & &1.id)
    assert ids == [building.id]
  end

  test "update_building/2 changes attributes" do
    customer = create_customer!()
    {:ok, building} = Buildings.create_building(customer.id, @valid_attrs)

    assert {:ok, updated} = Buildings.update_building(building, %{name: "New Name"})
    assert updated.name == "New Name"
  end

  test "delete_building/1 removes the building and stops its elevators" do
    customer = create_customer!()
    {:ok, building} = Buildings.create_building(customer.id, @valid_attrs)

    {:ok, elevator} =
      Elevators.create_elevator(%{building_id: building.id, min_floor: 1, max_floor: 10})

    assert {:ok, _state} = Elevators.get_elevator_state(elevator.id)

    assert {:ok, _deleted} = Buildings.delete_building(building)

    assert Buildings.get_building(building.id, customer.id) == {:error, :not_found}
    assert Elevators.get_elevator_state(elevator.id) == {:error, :not_found}
  end
end
