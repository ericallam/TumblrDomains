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

  match '/thank_you', :to => 'payments#thank_you', :as => 'payment_complete'
  match '/payment_problem', :to => 'payments#problem', :as => 'payment_problem'
  match '/registration_problem', :to => 'payments#registration_problem', :as => 'registration_problem'

  root :to => 'home#index'
end


