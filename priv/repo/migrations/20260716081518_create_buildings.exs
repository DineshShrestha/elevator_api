defmodule ElevatorApi.Repo.Migrations.CreateBuildings do
  use Ecto.Migration

  def change do
    create table(:buildings) do
      add :name, :string, null: false
      add :address, :string
      add :min_floor, :integer, null: false
      add :max_floor, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create constraint(
             :buildings,
             :valid_floor_range,
             check: "min_floor < max_floor"
           )
  end
end
