defmodule ElevatorApiWeb.Schema do
  use Absinthe.Schema

  alias ElevatorApiWeb.Resolvers.ElevatorResolver

  import_types(ElevatorApiWeb.Schema.ElevatorTypes)

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
  end

  mutation do
    field :request_hall_call, :elevator_state do
      arg(:floor, non_null(:integer))
      arg(:direction, non_null(:hall_direction))
      resolve(&ElevatorResolver.request_hall_call/3)
    end
  end
end
