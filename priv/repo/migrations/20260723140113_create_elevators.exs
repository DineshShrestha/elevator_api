defmodule ElevatorApi.Repo.Migrations.CreateElevators do
  use Ecto.Migration

  def change do
    create table(:elevators) do
      add :building_id, references(:buildings, on_delete: :delete_all), null: false
      add :min_floor, :integer, null: false
      add :max_floor, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:elevators, [:building_id])

    create constraint(
             :elevators,
             :valid_floor_range,
             check: "min_floor < max_floor"
           )
  end
end
