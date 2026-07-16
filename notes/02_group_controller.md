# Group Controller

The Group Controller assigns each hall request to the best elevator.

## Hall request

A hall request contains:

```text
floor
direction
```

Example:

```text
floor: 6
direction: up
```

## Group Controller responsibilities

The Group Controller must:

* receive hall requests from the Elevators context
* inspect all elevator runtime states
* ignore unavailable elevators
* calculate a score for each available elevator
* assign the request to the elevator with the lowest score

## Request flow

```text
GraphQL mutation
→ Resolver
→ Elevators context
→ Group Controller
→ Selected Elevator GenServer
```

## Elevator eligibility rules

Reject an elevator when:

* mode is maintenance
* mode is emergency
* mode is out of service
* load is full

An elevator moving up is suitable when:

* the request floor is above its current floor
* the hall request direction is up

An elevator moving down is suitable when:

* the request floor is below its current floor
* the hall request direction is down

An idle elevator is suitable for requests in either direction.

## Scoring factors

The first version uses:

```text
score =
distance
+ direction penalty
+ pending-stop penalty
```

### Distance

```text
absolute value of request floor minus current floor
```

Example:

```text
Elevator floor: 2
Request floor: 6
Distance: 4
```

### Direction penalty

Use no penalty when:

* elevator is idle
* elevator moves toward the request
* elevator direction matches the hall request

Add a large penalty when:

* request floor is behind the elevator
* elevator direction conflicts with the hall request

### Pending-stop penalty

Add a small penalty for every existing stop.

Example:

```text
3 pending stops
Penalty: 3
```

## Tie-breaking rules

When two elevators have the same score:

1. choose the elevator with fewer pending stops
2. choose the elevator with lower load
3. choose the elevator idle for longer
4. choose the lower elevator ID

The first implementation will use elevator ID as the final deterministic rule.

## Example 1

```text
Elevator A
Floor: 4
Direction: up
Target: 8

Hall request
Floor: 6
Direction: up
```

Elevator A should take the request because floor 6 lies ahead and the direction matches.

## Example 2

```text
Elevator A
Floor: 7
Direction: up
Target: 10

Hall request
Floor: 5
Direction: up
```

Elevator A should not take the request because floor 5 lies behind it.

## Example 3

```text
Elevator A
Floor: 4
Direction: up

Hall request
Floor: 6
Direction: down
```

Elevator A should not stop during its upward route. The hall request direction does not match.

## Example 4

```text
Elevator A
Floor: 3
Direction: idle

Elevator B
Floor: 5
Direction: down
Target: 1

Hall request
Floor: 4
Direction: down
```

Elevator B should receive the request because floor 4 lies ahead and the direction matches.

## First-version rule

```text
Choose an available elevator already moving toward the request in the correct direction.

When none exists, choose the nearest idle elevator.
```
