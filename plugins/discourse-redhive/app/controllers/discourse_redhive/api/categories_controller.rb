# frozen_string_literal: true

class DiscourseRedhive::Api::CategoriesController < DiscourseRedhive::Api::BaseController
  def index
    categories = Category.secured(guardian).where(parent_category_id: nil).order(:position)

    render json: {
      categories: categories.map do |c|
        {
          id: c.id,
          name: c.name,
          slug: c.slug,
          description: c.description,
          topic_count: c.topic_count,
          color: c.color,
        }
      end,
    }
  end
end
