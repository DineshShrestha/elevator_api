defmodule ElevatorApi.Repo do
  use Ecto.Repo,
    otp_app: :elevator_api,
    adapter: Ecto.Adapters.Postgres
end
