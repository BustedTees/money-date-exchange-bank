**Date Exchange Bank**
A gem that adds a `Money::Bank` with an ability to exchange_with a date or a given rate.

*Usage:*

```
require 'money/bank/date_exchange_bank'

Money.default_bank = Money::Bank::DateExchangeBank.new
```

The `DateExchangeBank` can also take a callable importer for exchange rate importing and updating.
The callable importer should add rates by calling the provided function.

A basic importer could look something like:
```
importer = ->(add_rate) { add_rate.call('USD', 'EUR', 0.75) }
```

**Money Extension**

A module that overrides the `Money#exchange_to` method to add support for exchanges with a date or a provided rate.
This can be used alongside the `Money::Bank::DateExchangeBank` and a custom `Store` to support exchanging with historical exchange rates or a known rate.

```
require 'money/extensions'

Money.include Extensions::Money

Money.new(1000, 'USD').exchange_to('EUR', date: Time.new(2018, 8, 7))
Money.new(1000, 'USD').exchange_to('EUR', rate: 0.75)
```
