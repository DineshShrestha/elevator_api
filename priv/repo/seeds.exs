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

alias ElevatorApi.Customers
alias ElevatorApi.Elevators.Elevator
alias ElevatorApi.Repo

{:ok, customer, api_key} = Customers.create_customer("Dev Customer")

building =
  Repo.insert!(%ElevatorApi.Buildings.Building{
    customer_id: customer.id,
    name: "Office Tower",
    address: "Main Street 10",
    min_floor: 1,
    max_floor: 10
  })

Repo.insert!(%Elevator{building_id: building.id, min_floor: 1, max_floor: 10})
Repo.insert!(%Elevator{building_id: building.id, min_floor: 1, max_floor: 10})

IO.puts("""

Seeded "Dev Customer" — use this API key for local testing:

  #{api_key}

(shown once; re-run `mix ecto.reset` to generate a new one)
""")
