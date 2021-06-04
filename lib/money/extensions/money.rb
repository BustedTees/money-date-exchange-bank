# frozen_string_literal: true

require 'money'

module Extensions
  # MonkeyPatch of the Money class to allow for exchange_to with date or rate.
  module Money
    def self.included(base)
      base.class_eval do
        alias_method :orig_exchange_to, :exchange_to
        def exchange_to(other_currency, date: nil, rate: nil, &rounding_method)
          other_currency = ::Money::Currency.wrap(other_currency)

          if currency == other_currency
            self
          else
            @bank.exchange_with(self, other_currency, date: date, rate: rate, &rounding_method)
          end
        end
      end
    end
  end
end
