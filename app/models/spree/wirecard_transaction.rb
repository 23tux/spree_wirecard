require 'wirecard/response'

module Spree
  class WirecardTransaction < ActiveRecord::Base
    has_many :payments, :as => :source

    serialize :params, Hash

    validate :check_fingerprint, :if => Proc.new { |transaction|
      return true if transaction.payments.empty?
      !transaction.payments.first.state=="pending" &&
      !transaction.payments.first.state=="failed" &&
      !transaction.payments.first.state=="void"
    }

    attr_accessor :payment_method

    def self.create_from_params(payment_method, params)
      build_from_params(payment_method, params).tap(&:save!)
    end

    def self.build_from_params(payment_method, params)
      new do |wirecard_transaction|
        wirecard_transaction.payment_method = payment_method
        wirecard_transaction.params = params
      end
    end

    def params=(params)
      @response = Wirecard::Response.new(payment_method, params)

      self.order_number = @response.order_number
      self.amount = @response.amount
      self.currency = @response.currency
      self.payment_type = @response.payment_type

      super
    end

    def success?
      @response.success?
    end

    def actions
      %w{capture void}
    end

    private
    def can_capture? *args
      payment.pending?
    end

    def can_void? *args
      payment.pending?
    end

    def check_fingerprint
      errors[:base] << 'Invalid respone fingerprint.' unless @response.has_valid_fingerprint?
    end

  end
end
