Rails.application.routes.draw do

  get '/excel_prices/:id/import', to: 'excel_prices#import', as: 'import_excel_price'
  get '/excel_prices/:id/file_export', to: 'excel_prices#file_export', as: 'file_export_excel_price'
  resources :excel_prices do
    collection do
      get :check_file_status
      post :delete_selected
      get :get_full_catalog
    end
  end
  resources :kp_products do
    member do
      put :update_by_bip
      get :update_modal
      patch :update_by_js
  end
  end
  get 'kps', to: 'kps#index_all'
  resources :orders do
    resources :kps do
      collection do
        get '/:id/copy', action: 'copy', as: 'copy'
        get '/:id/print1', action: 'print1', as: 'print1'
        get '/:id/print2', action: 'print2', as: 'print2'
        get '/:id/print3', action: 'print3', as: 'print3'
        get '/:id/print4', action: 'print4', as: 'print4'
        get '/:id/print1c', action: 'print1c', as: 'print1c'
        get ':id/file_import', action: 'file_import', as: 'file_import'
        get ':id/file_export', action: 'file_export', as: 'file_export'
        post ':id/import', action: 'import', as: 'import'
        get :autocomplete_product_title
      end
    end
    collection do
      post :delete_selected
      get :download
      post :webhook
      get :autocomplete_company_title
      get :autocomplete_client_name
    end
  end
  resources :products do
    collection do
      post :delete_selected
      get :insales_import
      delete '/:id/images/:image_id', action: 'delete_image', as: 'delete_image'
    end
  end
  resources :companies do
    collection do
      delete '/:id/images/:image_id', action: 'delete_image', as: 'delete_image'
    end
  end
  resources :clients
  root to: 'orders#index'
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords'
  }
  resources :users do
    collection do
      delete '/:id/images/:image_id', action: 'delete_image', as: 'delete_image'
    end
  end

  authenticated :user, -> user { user.admin? }  do
    mount DelayedJobWeb, at: "/job"
  end

end
