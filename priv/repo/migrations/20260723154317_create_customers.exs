defmodule ElevatorApi.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string, null: false
      add :api_key_hash, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:customers, [:api_key_hash])
  end
end
