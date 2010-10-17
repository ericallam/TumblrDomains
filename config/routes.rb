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

  root :to => 'home#index'
end


