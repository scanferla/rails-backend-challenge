class AppointmentsController < ApplicationController
  # POST /appointments
  # Params: client_id, provider_id, starts_at, ends_at
  def create
    raise NotImplementedError, "Implement appointment booking endpoint"
  end

  # DELETE /appointments/:id
  # Bonus: cancel an appointment instead of deleting
  def destroy
    raise NotImplementedError, "Implement appointment cancelation endpoint"
  end
end
