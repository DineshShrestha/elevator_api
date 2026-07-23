# ElevatorApi

A Phoenix + GraphQL (Absinthe) API for simulating and controlling a building's elevator system.

## Status

Implemented so far:

  * `Buildings.Building` and `Elevators.Elevator` schemas (floor range, `belongs_to` building) with DB migrations
  * `Elevators.ElevatorState` struct representing one elevator's runtime state (floor, direction, door state, mode, pending requests)
  * `Elevators.ElevatorServer`, a GenServer per elevator (registered in `ElevatorApi.Elevators.Registry`, supervised by `ElevatorApi.Elevators.ElevatorSupervisor`), started for every persisted elevator on boot
  * `Elevators.GroupController`, implementing the hall request assignment rules from the design notes: eligibility (rejects maintenance/emergency/out-of-service elevators), a distance + direction-penalty + pending-stop-penalty score, with elevator ID as the tie-break
  * GraphQL: `elevators`/`elevator(id)` queries and a `requestHallCall(floor, direction)` mutation

Not yet implemented: physical movement simulation (an elevator doesn't actually travel between floors or open/close its doors over time — hall/car requests are recorded on the target `ElevatorState` but nothing "ticks"). See [`notes/`](notes) for the design docs:

  * [`notes/01_elevator_state.md`](notes/01_elevator_state.md) — elevator runtime state
  * [`notes/02_group_controller.md`](notes/02_group_controller.md) — hall request assignment rules

## Getting started

To start your Phoenix server:

  * Run `mix setup` to install dependencies and set up the database
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Visit [`localhost:4000/graphiql`](http://localhost:4000/graphiql) to explore the GraphQL API. `mix setup` seeds one building with two elevators, so you can try:

```graphql
{ elevators { id currentFloor direction mode } }

mutation {
  requestHallCall(floor: 6, direction: UP) {
    id
    currentFloor
    direction
    pendingUp
  }
}
```

If port 4000 is already in use by another running instance, change the `port:` value in `config/dev.exs`, or verify the schema directly without a browser:

```
mix run -e '
  {:ok, %{data: data}} = Absinthe.run("{ elevators { id currentFloor direction mode } }", ElevatorApiWeb.Schema)
  IO.inspect(data)
'
```

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
