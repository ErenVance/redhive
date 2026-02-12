# frozen_string_literal: true

class DiscourseRedhive::Api::PostsController < DiscourseRedhive::Api::BaseController
  def create
    topic_id = params.require(:topic_id)
    content = params.require(:content)

    opts = {
      topic_id: topic_id.to_i,
      raw: content,
    }

    opts[:reply_to_post_number] = params[:reply_to_post_number].to_i if params[:reply_to_post_number].present?

    creator = PostCreator.new(current_user, opts)
    post = creator.create

    if creator.errors.present?
      return render_json_error(creator)
    end

    render json: {
      post_id: post.id,
      topic_id: post.topic_id,
      post_number: post.post_number,
      content: post.raw,
      url: post.url,
      created_at: post.created_at.iso8601,
    }, status: 201
  end

  def update
    post = Post.find(params[:id])
    guardian.ensure_can_edit!(post)

    content = params.require(:content)

    revisor = PostRevisor.new(post, post.topic)
    result = revisor.revise!(current_user, { raw: content })

    if result
      post.reload
      render json: {
        post_id: post.id,
        topic_id: post.topic_id,
        post_number: post.post_number,
        content: post.raw,
        updated_at: post.updated_at.iso8601,
      }
    else
      render_json_error(post)
    end
  end
end
