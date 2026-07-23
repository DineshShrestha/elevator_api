# ElevatorApi

A Phoenix + GraphQL (Absinthe) API for simulating and controlling a building's elevator system.

## Status

Early stage. Implemented so far:

  * `Buildings.Building` schema (name, address, floor range) with DB migrations
  * `Elevators.ElevatorState` struct representing one elevator's runtime state (floor, direction, door state, mode, pending requests)
  * A minimal GraphQL schema exposing a `health` query

The group controller (hall request assignment) and per-elevator GenServers are designed but not yet implemented. See [`notes/`](notes) for the design docs:

  * [`notes/01_elevator_state.md`](notes/01_elevator_state.md) — elevator runtime state
  * [`notes/02_group_controller.md`](notes/02_group_controller.md) — hall request assignment rules

## Getting started

To start your Phoenix server:

  * Run `mix setup` to install dependencies and set up the database
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Visit [`localhost:4000/graphiql`](http://localhost:4000/graphiql) to explore the GraphQL API.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
