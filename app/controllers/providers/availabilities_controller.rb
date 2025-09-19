module Providers
  class AvailabilitiesController < ApplicationController
    # GET /providers/:provider_id/availabilities
    # Expected params: from, to (ISO8601 timestamps)
    def index
      raise NotImplementedError, "Implement availability search endpoint"
    end
  end
end
