### Gauge

- Abstract contract used to implement rate limits.

### Vault

- Contract on non Aevo chains.
- Lock and unlock amounts.
- Implements Gauge.
  - Revert on lock trottle.
  - Store pending and unlock later on unlock throttle.

### Controller

- Contract on Aevo chain.
- Has mint and burn rights on token.
- Calls ExchangeRate contract for lock >> mint and burn >> unlock conversion.
- Implements sibling chain specific Gauge.
  - Revert on burn trottle.
  - Store pending and mint later on mint throttle.

### ExchangeRate

- Contract for lock >> mint and burn >> unlock conversion.
- Enables path to AMM based bridging.

### Todo

- [ ] Connector Plugs
- [ ] Multi token support
- [ ] Update only rate and max limits of LimitParams
- [ ] Errors and events
- [ ] Rescue, pause functions
- [ ]
