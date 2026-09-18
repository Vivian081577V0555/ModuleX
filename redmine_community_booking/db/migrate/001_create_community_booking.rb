class CreateCommunityBooking < ActiveRecord::Migration[6.1]
  def change
    create_table :community_booking_facilities do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :capacity, null: false, default: 1
      t.integer :opening_hour, null: false, default: 8
      t.integer :closing_hour, null: false, default: 22
      t.boolean :active, null: false, default: true
      t.timestamps null: false
    end

    add_index :community_booking_facilities, :project_id

    create_table :community_bookings do |t|
      t.integer :project_id, null: false
      t.integer :community_booking_facility_id, null: false
      t.integer :user_id, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :quantity, null: false, default: 1
      t.string :status, null: false, default: 'booked'
      t.text :notes
      t.timestamps null: false
    end

    add_index :community_bookings, :project_id
    add_index :community_bookings, :community_booking_facility_id
    add_index :community_bookings, [:community_booking_facility_id, :starts_at], name: 'idx_comm_bookings_facility_start'
    add_index :community_bookings, :user_id
  end
end
