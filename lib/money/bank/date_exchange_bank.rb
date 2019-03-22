# frozen_string_literal: true

require 'money'

class Money
  module Bank
    # A Money::Bank that can be used with default stores or stores with support
    # for historical exchange rate lookup.
    # This Bank can also be used with the Extensions::Money to allow exchange_to
    # to take optional date and rate params.
    class DateExchangeBank < Money::Bank::VariableExchange
      def initialize(store = Money::RatesStore::Memory.new, &block)
        @store = store
        @get_rate_arg_count = store.method(:get_rate).arity

        super(&block)
      end

      def exchange_with(from, to_currency, date: Time.now, rate: nil, &block)
        to_currency = Money::Currency.wrap(to_currency)
        return from if from.currency == to_currency

        rate = if rate.nil?
                 get_rate(from.currency, to_currency, date: date)
               else
                 wrap_rate(rate)
               end

        raise UnknownRate, "No conversion rate known for '#{from.currency.iso_code}' -> '#{to_currency}'" if rate.nil?

        fractional = calculate_fractional(from, to_currency)
        from.class.new(exchange(fractional, rate, &block), to_currency)
      end

      def get_rate(from_currency, to_currency, date: Time.now)
        from_iso_code = Money::Currency.wrap(from_currency).iso_code
        to_iso_code = Money::Currency.wrap(to_currency).iso_code

        if @get_rate_arg_count == 2 # Support Money store interface.
          store.get_rate(from_iso_code, to_iso_code)
        elsif @get_rate_arg_count == 3
          store.get_rate(from_iso_code, to_iso_code, date: date)
        end
      end

      private

      def wrap_rate(rate)
        return if rate.nil?

        if rate.is_a?(Numeric)
          BigDecimal(rate.to_s)
        elsif rate.respond_to?(:rate)
          BigDecimal(rate.rate.to_s)
        else
          msg = "Supplied rate: #{rate} is not valid. "\
            'Must be of type Numeric or an Object that responds to #rate.'
          raise ArgumentError, msg
        end
      end
    end
  end
end
