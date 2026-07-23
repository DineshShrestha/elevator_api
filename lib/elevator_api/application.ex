defmodule ElevatorApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElevatorApiWeb.Telemetry,
      ElevatorApi.Repo,
      {DNSCluster, query: Application.get_env(:elevator_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElevatorApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ElevatorApi.Finch},
      {Registry, keys: :unique, name: ElevatorApi.Elevators.Registry},
      ElevatorApi.Elevators.ElevatorSupervisor,
      # Start to serve requests, typically the last entry
      ElevatorApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElevatorApi.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      ElevatorApi.Elevators.start_all_from_db()
      {:ok, pid}
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElevatorApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
