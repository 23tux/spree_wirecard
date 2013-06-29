require 'spree/wirecard_transaction'

module Spree
  module WirecardQPAYHelpers
    def find_or_create_wirecard_qpay_payment(order, params)
      payment_method = PaymentMethod.find(params[:payment_method_id])
      payment = order.payments.find_by_payment_method_id(params[:payment_method_id])
      wirecard_transaction = Spree::WirecardTransaction.build_from_params(payment_method, params)

      if payment.present?
        payment.source = wirecard_transaction
        payment.save!
      else
        payment = order.payments.create({
          :amount => params[:amount],
          :source => wirecard_transaction,
          :payment_method => payment_method,
        }, :without_protection => true)
        payment.started_processing!
        payment.pend!
      end

      payment
    end

    def finalize_wirecard_qpay_payment(order, payment)
      order.update_attributes({ :state => 'complete', :completed_at => Time.current }, :without_protection => true)
      state_callback(:after)
      order.finalize!
    end

    def fail_wirecard_qpay_payment(order, payment)
      payment.failure!
    end
  end
end
