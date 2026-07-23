defmodule ElevatorApi.Customers do
  alias ElevatorApi.Customers.Customer
  alias ElevatorApi.Repo

  @doc """
  Creates a customer and returns its plaintext API key. The plaintext is
  never stored (only its hash is) and is not recoverable afterward.
  """
  def create_customer(name) do
    token = generate_token()

    %Customer{}
    |> Customer.changeset(%{name: name, api_key_hash: hash_key(token)})
    |> Repo.insert()
    |> case do
      {:ok, customer} -> {:ok, customer, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_customer_by_api_key(token) when is_binary(token) do
    case Repo.get_by(Customer, api_key_hash: hash_key(token)) do
      nil -> {:error, :not_found}
      customer -> {:ok, customer}
    end
  end

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp hash_key(token) do
    :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
  end
end
