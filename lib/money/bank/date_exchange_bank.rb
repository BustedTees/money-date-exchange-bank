# frozen_string_literal: true

require 'money'

class Money
  module Bank
    # A Money::Bank that can be used with default stores or stores with support
    # for historical exchange rate lookup.
    # This Bank can also be used with the Extensions::Money to allow exchange_to
    # to take optional date and rate params.
    class DateExchangeBank < Money::Bank::Base
      attr_reader :store

      # @param store [Object] an instance of a Money store that responds to the
      #   methods as defined by `gem money`.
      # @param importer [Object] a callable object that takes a proc to add
      #   rates to the bank.
      # @return [Money::Bank::DateExchangeBank] an instance of the bank.
      #
      # @example
      #   store = Money::RatesStore::Memory.new
      #   importer = ->(add_rate) { add_rate.call('USD', 'EUR', 0.75) }
      #   bank = Money::Bank::DateExchangeBank.new(store, importer: importer)
      def initialize(store = Money::RatesStore::Memory.new, importer: nil, &block)
        @store = store
        @importer = importer
        super(&block)
      end

      # Registers a conversion rate and returns it (uses +#set_rate+).
      # Delegates to +@store+
      #
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      # @param [Numeric] rate Rate to use when exchanging currencies.
      #
      # @return [Numeric]
      #
      # @example
      #   bank = Money::Bank::DateExchangeBank.new
      #   bank.add_rate("USD", "CAD", 1.24515)
      #   bank.add_rate("CAD", "USD", 0.803115)
      def add_rate(from, to, rate)
        set_rate(from, to, rate)
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
        elsif @get_rate_arg_count == -3
          store.get_rate(from_iso_code, to_iso_code, date: date)
        end
      end

      def import_rates
        return if @importer.nil?

        @importer&.call(method(:add_rate))
      end

      # From Money::Bank::VariableExchange
      def marshal_dump
        [store.marshal_dump, @rounding_method]
      end

      # From Money::Bank::VariableExchange
      def marshal_load(arr)
        store_info = arr[0]
        @store = store_info.shift.new(*store_info)
        @rounding_method = arr[1]
      end

      private

      # From Money::Bank::VariableExchange
      def calculate_fractional(from, to_currency)
        BigDecimal(from.fractional.to_s) / (
          BigDecimal(from.currency.subunit_to_unit.to_s) /
          BigDecimal(to_currency.subunit_to_unit.to_s)
        )
      end

      # From Money::Bank::VariableExchange
      def exchange(fractional, rate)
        ex = fractional * BigDecimal(rate.to_s)

        if block_given?
          yield ex
        elsif @rounding_method
          @rounding_method.call(ex)
        else
          ex
        end
      end

      def setup
        @get_rate_arg_count = store.method(:get_rate).arity
        self
      end

      # From Money::Bank::VariableExchange
      def set_rate(from, to, rate)
        store.add_rate(
          Currency.wrap(from).iso_code, Currency.wrap(to).iso_code, rate
        )
      end

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
