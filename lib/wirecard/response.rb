# encoding: utf-8

module Wirecard
  # Potential params for response (for details check the QPAY documentation).
  #
  # (S) ... for successful payments
  # (C) ... for cancelled payments
  # (F) ... for failed payments
  #
  # Params:
  #
  # - paymentState (S, C, F)
  # - amount (S)
  # - currency (S)
  # - paymentType (S)
  # - financialInstitution (S)
  # - language (S)
  # - orderNumber (S)
  # - responseFingerprint (S)
  # - responseFingerprintOrder (S)
  # - anonymousPan (S)
  # - authenticated (S)
  # - message (F)
  # ... + lots of custom parameters for different payment types
  class Response
    attr_accessor :payment_method, :params

    def to_s
      if failure?
        # payment method acts as a simple string and holds the error string
        "#{payment_method}"
      else
        super
      end
    end

    def initialize(payment_method, params = {})
      self.payment_method = payment_method
      self.params = params.with_indifferent_access
    end

    def amount
      @amount ||= BigDecimal.new(params[:amount]) rescue nil
    end

    def success?; payment_state == 'SUCCESS'; end
    def cancelled?; payment_state == 'CANCEL'; end
    def failure?; payment_state == 'FAILURE'; end

    def has_valid_fingerprint?
      fingerprint_params = response_fingerprint_order.split(',').map(&:to_sym)
      fingerprint_seed = params.merge(:secret => payment_method.preferences[:secret]).values_at(*fingerprint_params).join
      expected_fingerprint = Wirecard.md5(fingerprint_seed)
      response_fingerprint.present? && response_fingerprint == expected_fingerprint
    end

    def respond_to?(method, include_private = false)
      return true if params.key?(method)
      return true if params.key?(method.to_s.camelize(:lower))
      super
    end

  private

    def method_missing(method, *args, &block)
      return params[method] if params.key?(method)
      return params[method.to_s.camelize(:lower)] if params.key?(method.to_s.camelize(:lower))
      super
    end
  end
end
