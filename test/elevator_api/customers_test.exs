defmodule ElevatorApi.CustomersTest do
  use ElevatorApi.DataCase, async: true

  alias ElevatorApi.Customers

  test "create_customer/1 returns the customer and a plaintext key" do
    assert {:ok, customer, api_key} = Customers.create_customer("Acme Corp")

    assert customer.name == "Acme Corp"
    assert is_binary(api_key)
    assert byte_size(api_key) > 0
    # only the hash is persisted, never the plaintext
    refute customer.api_key_hash == api_key
  end

  test "get_customer_by_api_key/1 finds the customer for a valid key" do
    {:ok, customer, api_key} = Customers.create_customer("Acme Corp")

    assert Customers.get_customer_by_api_key(api_key) == {:ok, customer}
  end

  test "get_customer_by_api_key/1 returns not_found for an unknown key" do
    assert Customers.get_customer_by_api_key("nonexistent") == {:error, :not_found}
  end

  test "each customer gets a distinct key" do
    {:ok, _c1, key1} = Customers.create_customer("Acme Corp")
    {:ok, _c2, key2} = Customers.create_customer("Globex")

    refute key1 == key2
  end
end
