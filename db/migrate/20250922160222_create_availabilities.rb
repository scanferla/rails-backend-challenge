class CreateAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :availabilities do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :source, null: false
      t.string :external_id, null: false
      t.integer :start_day_of_week, null: false
      t.time :start_time, null: false
      t.integer :end_day_of_week, null: false
      t.time :end_time, null: false

      t.timestamps
    end

    add_index :availabilities, [ :provider_id, :source, :external_id ], unique: true, name: "index_availabilities_on_provider_source_external_id"
    add_check_constraint :availabilities, "start_day_of_week BETWEEN 0 AND 6", name: "check_availabilities_start_day_of_week_range"
    add_check_constraint :availabilities, "end_day_of_week BETWEEN 0 AND 6", name: "check_availabilities_end_day_of_week_range"
  end
end
