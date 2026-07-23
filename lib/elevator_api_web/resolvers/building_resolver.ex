defmodule ElevatorApiWeb.Resolvers.BuildingResolver do
  alias ElevatorApi.Buildings
  alias ElevatorApiWeb.ChangesetErrors

  def list_buildings(_parent, _args, _resolution) do
    {:ok, Buildings.list_buildings()}
  end

  def get_building(_parent, %{id: id}, _resolution) do
    case Buildings.get_building(id) do
      {:ok, building} -> {:ok, building}
      {:error, :not_found} -> {:ok, nil}
    end
  end

  def create_building(_parent, %{input: input}, _resolution) do
    case Buildings.create_building(input) do
      {:ok, building} -> {:ok, building}
      {:error, changeset} -> {:error, ChangesetErrors.to_message(changeset)}
    end
  end

  def update_building(_parent, %{id: id, input: input}, _resolution) do
    with {:ok, building} <- Buildings.get_building(id),
         {:ok, updated} <- Buildings.update_building(building, input) do
      {:ok, updated}
    else
      {:error, :not_found} -> {:error, "building not found"}
      {:error, changeset} -> {:error, ChangesetErrors.to_message(changeset)}
    end
  end

  def delete_building(_parent, %{id: id}, _resolution) do
    with {:ok, building} <- Buildings.get_building(id),
         {:ok, deleted} <- Buildings.delete_building(building) do
      {:ok, deleted}
    else
      {:error, :not_found} -> {:error, "building not found"}
      {:error, changeset} -> {:error, ChangesetErrors.to_message(changeset)}
    end
  end
end
