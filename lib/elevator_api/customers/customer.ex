defmodule ElevatorApi.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :name, :string
    field :api_key_hash, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :api_key_hash])
    |> validate_required([:name, :api_key_hash])
    |> unique_constraint(:api_key_hash)
  end
end
