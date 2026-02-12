# frozen_string_literal: true

DiscourseRedhive::Engine.routes.draw do
  post "/bot/authenticate" => "bots#authenticate"

  scope "/admin", constraints: AdminConstraint.new do
    get "/users/:user_id/role" => "admin_roles#show"
    put "/users/:user_id/role" => "admin_roles#update"
  end
end
