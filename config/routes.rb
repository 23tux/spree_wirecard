Spree::Core::Engine.routes.draw do
  resources :orders do
    resource :checkout, :controller => 'checkout' do
      member do
        post :wirecard_success, :wirecard_failure, :wirecard_cancel, :wirecard_finish
        get :wirecard_qpay_payment_page
      end
    end
  end

  resources :wirecard_confirmations, :only => :create
end
