module Providers
  class AvailabilitiesController < ApplicationController
    before_action :set_provider, only: :index
    before_action :validate_availability_request, only: :index

    # GET /providers/:provider_id/availabilities
    # Expected params: from, to (ISO8601 timestamps)
    def index
      result = Providers::Availabilities::FreeSlots.call(
        provider: @provider,
        from: @availability_params.from,
        to: @availability_params.to
      )

      if result.success?
        @free_slots = result.data[:free_slots]
        render :index
      else
        render_bad_request(result.error[:error])
      end
    end

    private

    def set_provider
      @provider = Provider.find(params[:provider_id])
    end

    def validate_availability_request
      @availability_params = TimeRangeParams.new(params.permit(:from, :to))
      return if @availability_params.valid?

      render_bad_request(@availability_params.errors.full_messages)
    end
  end
end
