class TimeRangeParams
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :from, :datetime
  attribute :to, :datetime

  validates :from, :to, presence: true
  validates :to, comparison: { greater_than: :from }
end
