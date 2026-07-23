defmodule ElevatorApi.Repo.Migrations.AddCustomerIdToBuildings do
  use Ecto.Migration

  def change do
    alter table(:buildings) do
      add :customer_id, references(:customers, on_delete: :delete_all)
    end

    create index(:buildings, [:customer_id])
  end
end
