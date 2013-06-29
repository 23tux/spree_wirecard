require 'wirecard'
require 'spree/billing_integration/wirecard/qpay'
require 'spree/wirecard_qpay_helpers'

module Spree
  CheckoutController.class_eval do
    include WirecardQPAYHelpers

    skip_before_filter :verify_authenticity_token, :only => [:wirecard_success, :wirecard_failure, :wirecard_cancel]
    before_filter :redirect_to_wirecard_form, :only => [:update]

    def wirecard_qpay_payment_page
      @payment_method = PaymentMethod.find(params[:payment_method_id])
      render :layout => false
    end

    def wirecard_success
      payment = find_or_create_wirecard_qpay_payment(@order, params)

      @redirect_url = completion_route

      unless payment.completed?
        if payment.source.success?
          finalize_wirecard_qpay_payment(@order, payment)
        else
          fail_wirecard_qpay_payment(@order, payment)

          @redirect_url = checkout_state_path(:payment)
        end
      end

      render :wirecard_qpay_redirect, :layout => false
    end

    def wirecard_failure
      @redirect_url = checkout_state_path(:payment)
      render :wirecard_qpay_redirect, :layout => false
    end

    def wirecard_cancel
      @redirect_url = checkout_state_path(:payment)
      render :wirecard_qpay_redirect, :layout => false
    end

    def redirect_to_wirecard_form
      return unless (params[:state] == "payment")
      return unless params[:order][:payments_attributes]

      payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      return unless payment_method.kind_of?(Spree::BillingIntegration::Wirecard::QPAY)

      load_order
      if not @order.errors.empty?
        render :edit and return
      end

      redirect_to(wirecard_qpay_payment_page_order_checkout_url(@order, :payment_method_id => payment_method.id)) and return
    end
  end
end
