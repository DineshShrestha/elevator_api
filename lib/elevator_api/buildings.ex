defmodule ElevatorApi.Buildings do
  import Ecto.Query

  alias ElevatorApi.Buildings.Building
  alias ElevatorApi.Elevators.{Elevator, ElevatorSupervisor}
  alias ElevatorApi.Repo

  def list_buildings do
    Repo.all(Building)
  end

  def get_building(id) do
    case Repo.get(Building, id) do
      nil -> {:error, :not_found}
      building -> {:ok, building}
    end
  end

  def create_building(attrs) do
    %Building{}
    |> Building.changeset(attrs)
    |> Repo.insert()
  end

  def update_building(%Building{} = building, attrs) do
    building
    |> Building.changeset(attrs)
    |> Repo.update()
  end

  def delete_building(%Building{} = building) do
    from(e in Elevator, where: e.building_id == ^building.id, select: e.id)
    |> Repo.all()
    |> Enum.each(&ElevatorSupervisor.stop_elevator/1)

    Repo.delete(building)
  end
end
