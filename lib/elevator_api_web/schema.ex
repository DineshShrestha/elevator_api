defmodule ElevatorApiWeb.Schema do
  use Absinthe.Schema

  query do
    field :health, :string do
      resolve(fn _, _, _ ->
        {:ok, "Elevator API is running"}
      end)
    end
  end
end
