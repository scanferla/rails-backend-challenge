class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :client, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_check_constraint :appointments, "ends_at > starts_at", name: "check_appointments_ends_after_starts"
  end
end
