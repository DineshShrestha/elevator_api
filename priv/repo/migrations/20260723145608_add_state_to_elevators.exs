defmodule ElevatorApi.Repo.Migrations.AddStateToElevators do
  use Ecto.Migration

  def change do
    alter table(:elevators) do
      add :state, :map
    end
  end
end
