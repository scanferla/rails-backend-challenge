class Provider < ApplicationRecord
  has_many :availabilities, dependent: :restrict_with_error
  has_many :appointments, dependent: :restrict_with_error
end
