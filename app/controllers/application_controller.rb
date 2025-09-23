class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def render_bad_request(message)
    render json: { error: message }, status: :bad_request
  end
end
