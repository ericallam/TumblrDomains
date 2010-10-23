Tumblrdomains::Application.routes.draw do
  
  resources :registrations do
    member do
      get :choose_tumblelog
    end

    collection do
      post :set_tumblelog
    end
  end

  match 'check_availability', :to => 'domains#check_availability', :as => 'check_availability'
  
  match '/payments/create', :to => 'payments#create', :as => 'payment_callback'

  root :to => 'home#index'
end


