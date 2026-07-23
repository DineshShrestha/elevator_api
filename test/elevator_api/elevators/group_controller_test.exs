defmodule ElevatorApi.Elevators.GroupControllerTest do
  use ExUnit.Case, async: true

  alias ElevatorApi.Elevators.{ElevatorState, GroupController, HallRequest}

  defp elevator(id, floor, opts \\ []) do
    %{
      ElevatorState.new(id, 1, 10)
      | current_floor: floor,
        direction: Keyword.get(opts, :direction, :idle),
        mode: Keyword.get(opts, :mode, :normal),
        pending_up: Keyword.get(opts, :pending_up, MapSet.new()),
        pending_down: Keyword.get(opts, :pending_down, MapSet.new()),
        car_requests: Keyword.get(opts, :car_requests, MapSet.new())
    }
  end

  describe "eligible?/1" do
    test "rejects maintenance, emergency, and out-of-service elevators" do
      for mode <- [:maintenance, :emergency, :out_of_service] do
        refute GroupController.eligible?(elevator("a", 1, mode: mode))
      end
    end

    test "accepts a normal-mode elevator" do
      assert GroupController.eligible?(elevator("a", 1, mode: :normal))
    end
  end

  describe "score/2" do
    test "is just the distance for an idle elevator with no pending stops" do
      state = elevator("a", 2)
      hall_request = HallRequest.new(6, :up)

      assert GroupController.score(state, hall_request) == 4
    end

    test "adds no direction penalty when moving toward the request in the same direction" do
      state = elevator("a", 4, direction: :up)
      hall_request = HallRequest.new(6, :up)

      assert GroupController.score(state, hall_request) == 2
    end

    test "adds a large direction penalty when the request is behind the elevator" do
      state = elevator("a", 7, direction: :up)
      hall_request = HallRequest.new(5, :up)

      assert GroupController.score(state, hall_request) > 500
    end

    test "adds a large direction penalty when directions conflict" do
      state = elevator("a", 4, direction: :up)
      hall_request = HallRequest.new(6, :down)

      assert GroupController.score(state, hall_request) > 500
    end

    test "adds a penalty for every pending stop" do
      state = elevator("a", 2, pending_up: MapSet.new([3, 4, 5]))
      hall_request = HallRequest.new(6, :up)

      assert GroupController.score(state, hall_request) == 4 + 3
    end
  end

  describe "assign/2" do
    test "returns an error when no elevator is eligible" do
      states = [elevator("a", 1, mode: :maintenance)]

      assert GroupController.assign(states, HallRequest.new(5, :up)) ==
               {:error, :no_available_elevator}
    end

    test "picks the elevator with the lowest score" do
      states = [
        elevator("far", 1),
        elevator("near", 5)
      ]

      assert GroupController.assign(states, HallRequest.new(6, :up)) == {:ok, "near"}
    end

    test "breaks ties by elevator id" do
      states = [
        elevator("b", 2),
        elevator("a", 2)
      ]

      assert GroupController.assign(states, HallRequest.new(6, :up)) == {:ok, "a"}
    end
  end
end
