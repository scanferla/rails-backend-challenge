class AddIndexesToAvailabilitiesAndAppointments < ActiveRecord::Migration[8.0]
  def change
    add_index :availabilities, [:provider_id, :start_day_of_week], name: "index_availabilities_on_provider_and_start_dow"
    add_index :availabilities, [:provider_id, :end_day_of_week], name: "index_availabilities_on_provider_and_end_dow"

    add_index :appointments, [:provider_id, :starts_at], name: "index_appointments_on_provider_and_starts_at"
    add_index :appointments, [:provider_id, :ends_at], name: "index_appointments_on_provider_and_ends_at"
  end
end
