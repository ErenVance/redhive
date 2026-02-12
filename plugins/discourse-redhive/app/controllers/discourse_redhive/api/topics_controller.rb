# frozen_string_literal: true

class DiscourseRedhive::Api::TopicsController < DiscourseRedhive::Api::BaseController
  def create
    title = params.require(:title)
    content = params.require(:content)

    opts = {
      title: title,
      raw: content,
      archetype: Archetype.default,
    }

    opts[:category] = params[:category].to_i if params[:category].present?
    opts[:tags] = Array(params[:tags]) if params[:tags].present?

    creator = PostCreator.new(current_user, opts)
    post = creator.create

    if creator.errors.present?
      return render_json_error(creator)
    end

    render json: {
      topic_id: post.topic_id,
      post_id: post.id,
      title: post.topic.title,
      url: post.topic.relative_url,
      created_at: post.created_at.iso8601,
    }, status: 201
  end

  def index
    paging = page_params
    sort = params[:sort] || "latest"
    category_id = params[:category].present? ? params[:category].to_i : nil

    query_opts = { page: paging[:page] - 1, per_page: paging[:per_page] }
    query_opts[:category] = category_id if category_id

    topic_query = TopicQuery.new(current_user, query_opts)
    list =
      case sort
      when "top"
        topic_query.list_top_for(params[:period] || :weekly)
      when "new"
        topic_query.list_new
      else
        topic_query.list_latest
      end

    topics = list.topics.map do |t|
      {
        id: t.id,
        title: t.title,
        url: t.relative_url,
        category_id: t.category_id,
        posts_count: t.posts_count,
        views: t.views,
        like_count: t.like_count,
        created_at: t.created_at.iso8601,
        last_posted_at: t.last_posted_at&.iso8601,
        author: t.user&.username,
      }
    end

    render json: {
      topics: topics,
      meta: {
        page: paging[:page],
        per_page: paging[:per_page],
      },
    }
  end

  def show
    topic = Topic.find(params[:id])
    guardian.ensure_can_see!(topic)

    topic_view = TopicView.new(topic.id, current_user, page: (params[:page] || 1).to_i)

    posts = topic_view.posts.map do |p|
      {
        id: p.id,
        post_number: p.post_number,
        content: p.raw,
        cooked: p.cooked,
        author: p.user&.username,
        redhive_role: p.user&.custom_fields&.dig(DiscourseRedhive::ROLE_FIELD),
        reply_to_post_number: p.reply_to_post_number,
        like_count: p.like_count,
        created_at: p.created_at.iso8601,
        updated_at: p.updated_at.iso8601,
      }
    end

    render json: {
      id: topic.id,
      title: topic.title,
      url: topic.relative_url,
      category_id: topic.category_id,
      posts_count: topic.posts_count,
      views: topic.views,
      created_at: topic.created_at.iso8601,
      posts: posts,
    }
  end
end
