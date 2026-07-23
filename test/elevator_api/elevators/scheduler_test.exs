defmodule ElevatorApi.Elevators.SchedulerTest do
  use ExUnit.Case, async: true

  alias ElevatorApi.Elevators.{ElevatorState, Scheduler}

  defp state(opts) do
    %{
      ElevatorState.new("a", 1, 10)
      | current_floor: Keyword.get(opts, :current_floor, 1),
        direction: Keyword.get(opts, :direction, :idle),
        door_state: Keyword.get(opts, :door_state, :closed),
        current_target: Keyword.get(opts, :current_target, nil),
        pending_up: Keyword.get(opts, :pending_up, MapSet.new()),
        pending_down: Keyword.get(opts, :pending_down, MapSet.new()),
        car_requests: Keyword.get(opts, :car_requests, MapSet.new())
    }
  end

  describe "has_work?/1" do
    test "is false for a fully idle elevator" do
      refute Scheduler.has_work?(state([]))
    end

    test "is true when there is a pending hall request" do
      assert Scheduler.has_work?(state(pending_up: MapSet.new([5])))
    end

    test "is true when the door is open" do
      assert Scheduler.has_work?(state(door_state: :open))
    end
  end

  describe "step/1 idle elevator" do
    test "picks the nearest pending floor as its target" do
      s = state(current_floor: 5, pending_up: MapSet.new([8]), car_requests: MapSet.new([3]))
      next = Scheduler.step(s)

      assert next.current_target == 3
      assert next.direction == :down
    end

    test "stays idle with no pending requests" do
      next = Scheduler.step(state([]))

      assert next.current_target == nil
      assert next.direction == :idle
      assert next.movement_state == :stopped
    end
  end

  describe "step/1 movement" do
    test "moves one floor toward the target" do
      s = state(current_floor: 3, current_target: 6, direction: :up)
      next = Scheduler.step(s)

      assert next.current_floor == 4
      assert next.direction == :up
      assert next.movement_state == :moving
    end

    test "moves down when the target is below" do
      s = state(current_floor: 6, current_target: 2, direction: :down)
      next = Scheduler.step(s)

      assert next.current_floor == 5
      assert next.direction == :down
    end
  end

  describe "step/1 arrival" do
    test "opens the door and clears the floor from every pending set on arrival" do
      s =
        state(
          current_floor: 5,
          current_target: 5,
          pending_up: MapSet.new([5]),
          car_requests: MapSet.new([5, 9])
        )

      next = Scheduler.step(s)

      assert next.door_state == :open
      assert next.movement_state == :stopped
      assert next.current_target == nil
      refute MapSet.member?(next.pending_up, 5)
      assert next.car_requests == MapSet.new([9])
    end

    test "closes the door on the next step" do
      s = state(door_state: :open)
      next = Scheduler.step(s)

      assert next.door_state == :closed
    end
  end

  describe "step/1 direction continuation" do
    test "keeps scanning up before reversing" do
      s = state(current_floor: 5, direction: :up, pending_up: MapSet.new([2, 8]))
      next = Scheduler.step(s)

      assert next.current_target == 8
      assert next.direction == :up
    end

    test "reverses direction once nothing is left ahead" do
      s = state(current_floor: 5, direction: :up, pending_down: MapSet.new([2]))
      next = Scheduler.step(s)

      assert next.current_target == 2
      assert next.direction == :down
    end
  end
end
