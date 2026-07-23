# ElevatorApi

A Phoenix + GraphQL (Absinthe) API for simulating and controlling a building's elevator system.

## Status

Implemented so far:

  * `Buildings.Building` and `Elevators.Elevator` schemas (floor range, `belongs_to` building) with DB migrations
  * `Elevators.ElevatorState` struct representing one elevator's runtime state (floor, direction, door state, mode, pending requests)
  * `Elevators.ElevatorServer`, a GenServer per elevator (registered in `ElevatorApi.Elevators.Registry`, supervised by `ElevatorApi.Elevators.ElevatorSupervisor`), started for every persisted elevator on boot
  * `Elevators.GroupController`, implementing the hall request assignment rules from the design notes: eligibility (rejects maintenance/emergency/out-of-service elevators), a distance + direction-penalty + pending-stop-penalty score, with elevator ID as the tie-break
  * GraphQL: `elevators`/`elevator(id)` and `buildings`/`building(id)` queries, `requestHallCall(buildingId, floor, direction)`, and full CRUD mutations for buildings/elevators (`createBuilding`/`updateBuilding`/`deleteBuilding`, `createElevator`/`updateElevator`/`deleteElevator`) — creating/updating/deleting an elevator starts/restarts/stops its `ElevatorServer` accordingly, and deleting a building stops every elevator that belonged to it. `requestHallCall` only assigns among elevators belonging to the given building, and rejects a floor outside that building's range.
  * `Elevators.Scheduler`, a discrete-tick movement simulation: once assigned a request, an elevator picks a target floor, travels one floor per tick (`config :elevator_api, :elevator_tick_interval_ms`, default 1000ms), opens its door on arrival, then closes it and goes idle — all reflected live in `ElevatorState`'s `direction`/`movement_state`/`door_state`/`current_target`/pending fields
  * API-key auth on `/graphql` (`x-api-key` header, checked with a constant-time comparison) — required in every environment; `/graphiql` is now dev-only (gated behind `dev_routes`, alongside LiveDashboard)
  * State durability: each elevator's live state is persisted (`elevators.state`, jsonb) on every request/tick and restored on boot, so a crash or redeploy resumes in place instead of resetting every elevator to idle at its min floor
  * CI (`.github/workflows/ci.yml`): `mix format --check-formatted` and `mix test` run against a Postgres service container on every push/PR

Known simplifications: once en route to a target floor, an elevator won't reroute mid-transit even if a closer request arrives — it finishes the current target, then re-scans for the next one; updating an elevator's floor range restarts its GenServer, resetting its live state (in-flight requests are dropped). See [`notes/`](notes) for the design docs:

  * [`notes/01_elevator_state.md`](notes/01_elevator_state.md) — elevator runtime state
  * [`notes/02_group_controller.md`](notes/02_group_controller.md) — hall request assignment rules

## Getting started

To start your Phoenix server:

  * Run `mix setup` to install dependencies and set up the database
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Every request to `/graphql` requires an `x-api-key` header — the dev default is `dev-local-key` (see `config/dev.exs`; production requires the `API_KEY` env var). `mix setup` seeds one building with two elevators, so you can try:

```graphql
{ elevators { id currentFloor direction mode } }

mutation {
  requestHallCall(buildingId: "1", floor: 6, direction: UP) {
    id
    currentFloor
    direction
    pendingUp
  }
}

mutation {
  createBuilding(input: { name: "Office Tower", minFloor: 1, maxFloor: 10 }) { id }
}
```

using a client that can set the header, e.g.:

```
curl http://localhost:4000/graphql \
  -H "content-type: application/json" \
  -H "x-api-key: dev-local-key" \
  -d '{"query": "{ elevators { id currentFloor direction mode } }"}'
```

[`localhost:4000/graphiql`](http://localhost:4000/graphiql) is available in dev only (gated behind `dev_routes`, disabled in prod) for interactively exploring the schema — it executes directly against the schema and does **not** require the `x-api-key` header, unlike the real `/graphql` endpoint.

If port 4000 is already in use by another running instance, change the `port:` value in `config/dev.exs`, or verify the schema directly without a browser or a real HTTP request:

```
mix run -e '
  {:ok, %{data: data}} = Absinthe.run("{ elevators { id currentFloor direction mode } }", ElevatorApiWeb.Schema)
  IO.inspect(data)
'
```

(this calls the schema directly and bypasses the `/graphql` API-key check, since it skips the router/plug pipeline entirely — useful for quick local checks, not a substitute for testing auth).

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
