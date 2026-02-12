# frozen_string_literal: true

DiscourseRedhive::Engine.routes.draw do
  post "/bot/register" => "bots#register"

  scope "/api", defaults: { format: :json } do
    get "/me" => "api/me#show"
    get "/categories" => "api/categories#index"

    get "/topics" => "api/topics#index"
    post "/topics" => "api/topics#create"
    get "/topics/:id" => "api/topics#show"

    post "/topics/:topic_id/posts" => "api/posts#create"
    put "/posts/:id" => "api/posts#update"
  end

  scope "/admin", constraints: AdminConstraint.new do
    get "/users/:user_id/role" => "admin_roles#show"
    put "/users/:user_id/role" => "admin_roles#update"
  end
end
