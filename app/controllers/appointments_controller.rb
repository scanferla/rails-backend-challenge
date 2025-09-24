class AppointmentsController < ApplicationController
  # POST /appointments
  # Params: client_id, provider_id, starts_at, ends_at
  def create
    @appointment = Appointment.new(appointment_params)

    if @appointment.save
      render :show, status: :created
    else
      render_bad_request(@appointment.errors.full_messages)
    end
  end

  # DELETE /appointments/:id
  # Cancel an appointment instead of deleting
  def destroy
    @appointment = Appointment.find(params[:id])

    @appointment.canceled!

    render :show, status: :ok
  end

  private

  def appointment_params
    params.require(:appointment).permit(:client_id, :provider_id, :starts_at, :ends_at)
  end
end
