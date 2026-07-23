# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ElevatorApi.Repo.insert!(%ElevatorApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ElevatorApi.Buildings.Building
alias ElevatorApi.Elevators.Elevator
alias ElevatorApi.Repo

building =
  Repo.insert!(%Building{
    name: "Office Tower",
    address: "Main Street 10",
    min_floor: 1,
    max_floor: 10
  })

Repo.insert!(%Elevator{building_id: building.id, min_floor: 1, max_floor: 10})
Repo.insert!(%Elevator{building_id: building.id, min_floor: 1, max_floor: 10})
