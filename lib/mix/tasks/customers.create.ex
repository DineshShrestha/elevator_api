defmodule Mix.Tasks.Customers.Create do
  use Mix.Task

  alias ElevatorApi.Customers

  @shortdoc "Onboards a new customer and prints their API key once"

  @moduledoc """
  Creates a customer and prints their plaintext API key.

      mix customers.create "Acme Corp"

  The key is only ever shown here — only its hash is stored. Hand it to the
  customer out-of-band; there's no way to recover it afterward (create a new
  customer if it's lost).
  """

  @impl Mix.Task
  def run([name]) do
    Mix.Task.run("app.start")

    case Customers.create_customer(name) do
      {:ok, customer, api_key} ->
        Mix.shell().info("Created customer ##{customer.id} (#{customer.name})")
        Mix.shell().info("API key (shown once): #{api_key}")

      {:error, changeset} ->
        Mix.raise("Could not create customer: #{inspect(changeset.errors)}")
    end
  end

  def run(_args) do
    Mix.raise("Usage: mix customers.create \"Customer Name\"")
  end
end
