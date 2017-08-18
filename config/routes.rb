Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :issues do
    member do
      patch :execute
    end
  end

  resources :jira_sessions, only: [:new, :create] do
    collection do
      delete :destroy
    end
  end

  root to: "issues#index"
end
