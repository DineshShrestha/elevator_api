Elevator runtime state

The elevator state represents the current condition of one elevator.

It stores:
- elevator ID
- valid floor range
- current floor
- direction
- movement state
- door state
- operating mode
- pending hall requests
- pending car requests
- current target

MapSet prevents duplicate floor requests.

Runtime state will later belong to one GenServer process.

The database will store configuration and history, while the GenServer stores current live state.