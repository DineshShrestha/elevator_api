defmodule ElevatorApiWeb.Schema do
  use Absinthe.Schema

  alias ElevatorApiWeb.Resolvers.{BuildingResolver, ElevatorResolver}

  import_types(ElevatorApiWeb.Schema.ElevatorTypes)
  import_types(ElevatorApiWeb.Schema.BuildingTypes)

  query do
    field :health, :string do
      resolve(fn _, _, _ ->
        {:ok, "Elevator API is running"}
      end)
    end

    field :elevators, list_of(:elevator_state) do
      resolve(&ElevatorResolver.list_elevators/3)
    end

    field :elevator, :elevator_state do
      arg(:id, non_null(:id))
      resolve(&ElevatorResolver.get_elevator/3)
    end

    field :buildings, list_of(:building) do
      resolve(&BuildingResolver.list_buildings/3)
    end

    field :building, :building do
      arg(:id, non_null(:id))
      resolve(&BuildingResolver.get_building/3)
    end
  end

  mutation do
    field :request_hall_call, :elevator_state do
      arg(:floor, non_null(:integer))
      arg(:direction, non_null(:hall_direction))
      resolve(&ElevatorResolver.request_hall_call/3)
    end

    field :create_building, :building do
      arg(:input, non_null(:building_input))
      resolve(&BuildingResolver.create_building/3)
    end

    field :update_building, :building do
      arg(:id, non_null(:id))
      arg(:input, non_null(:building_input))
      resolve(&BuildingResolver.update_building/3)
    end

    field :delete_building, :building do
      arg(:id, non_null(:id))
      resolve(&BuildingResolver.delete_building/3)
    end

    field :create_elevator, :elevator_state do
      arg(:input, non_null(:elevator_input))
      resolve(&ElevatorResolver.create_elevator/3)
    end

    field :update_elevator, :elevator_state do
      arg(:id, non_null(:id))
      arg(:input, non_null(:elevator_input))
      resolve(&ElevatorResolver.update_elevator/3)
    end

    field :delete_elevator, :elevator_state do
      arg(:id, non_null(:id))
      resolve(&ElevatorResolver.delete_elevator/3)
    end
  end
end
