require 'uri'
require 'net/http'

module Spree
  class BillingIntegration::Wirecard::QPAY < PaymentMethod
    preference :customer_id, :string
    preference :secret, :string
    preference :shop_id, :string
    preference :language, :string, :default => 'de'
    preference :currency, :string, :default => 'EUR'
    preference :payment_type, :string, :default => 'SELECT'
    preference :toolkit_password, :string
    preference :toolkit_url, :string, :default => "https://secure.wirecard-cee.com/qpay/toolkit.php"

    attr_accessible :preferred_customer_id, :preferred_secret, :preferred_shop_id,
    :preferred_language, :preferred_currency, :preferred_payment_type, :preferred_toolkit_password,
    :preferred_toolkit_url

    # function to convert a hash to the url format key1=value1&key2=value2
    def parameterize(params)
      URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
    end

    def payment_profiles_supported?
      true
    end

    def call_wirecard params, seed
      # generate the md5 fingerprint
      fingerprint = Wirecard.md5(seed)
      # add the fingerprint to the params
      params[:requestFingerprint] = fingerprint

      # generate the post params, the secret is NOT allowed to be included
      post_params = parameterize(params.except(:secret))

      # toolkit url
      uri = URI.parse(preferences[:toolkit_url])

      # new http object with ssl
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      # new post object
      request = Net::HTTP::Post.new(preferences[:toolkit_url])
      # set the request parameters
      request.body = post_params
      # finally, call wirecard and store the response
      http.request(request)
    end

    def capture payment, source, options
      # params
      params = { customerId: preferences[:customer_id], toolkitPassword: preferences[:toolkit_password],
        secret: preferences[:secret], command: "deposit", language: preferences[:language],
      orderNumber: source.order_number, amount: payment.capture_amount.to_f, currency: preferences[:currency] }

      # generate the seed with the given order provided to values_at
      seed = params.values_at(:customerId, :toolkitPassword, :secret, :command, :language, :orderNumber, :amount, :currency).join

      response = call_wirecard params, seed

      payment.response_code = response.body

      if response.body.index("paymentNumber=#{source.order_number}") && response.body.index("status=0")
        payment_state = "SUCCESS"
      else
        payment_state = "FAILURE"
      end
      payment.save!
      Wirecard::Response.new("#{payment_state}, #{payment.response_code}", {payment_state: payment_state, response_code: payment.response_code, avs_result: {code: "X"}, authorization: true})
    end

    def void

    end

    def get_details

    end
  end
end
