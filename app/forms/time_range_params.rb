class TimeRangeParams
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  # Contract:
  # - from/to are datetimes
  # - from is clamped to "now" (past is not returned for available slots, as they're not available anymore)
  # - to must be in the future and greater than from
  attribute :from, :datetime
  attribute :to, :datetime

  before_validation :clamp_from_to_now

  validates :from, :to, presence: true
  validates :to, comparison: { greater_than: :from }
  validate :to_must_be_in_future

  private

  def clamp_from_to_now
    return unless from.present?

    self.from = [ from, Time.zone.now ].max
  end

  def to_must_be_in_future
    return unless to.present?

    errors.add(:to, :greater_than, value: :now) unless to > Time.zone.now
  end
end
