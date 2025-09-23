class TimeRangeParams
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  # from is at least "now" (past is not returned for available slots, as they're not available anymore)
  # to must be strictly after from
  attribute :from, :datetime
  attribute :to, :datetime

  before_validation :clamp_from_to_now

  validates :from, :to, presence: true
  validates :to, comparison: { greater_than: :from }

  private

  def clamp_from_to_now
    return unless from.present?

    self.from = [ from, Time.zone.now ].max
  end
end
