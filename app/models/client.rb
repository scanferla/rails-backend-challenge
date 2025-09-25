class Client < ApplicationRecord
  has_many :appointments, dependent: :restrict_with_error
end
