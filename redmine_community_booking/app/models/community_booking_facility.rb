class CommunityBookingFacility < ActiveRecord::Base
  belongs_to :project
  has_many :bookings, class_name: 'CommunityBooking', dependent: :destroy

  validates :name, presence: true, length: { maximum: 120 }
  validates :capacity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 999 }
  validates :opening_hour, :closing_hour, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }
  validate :closing_hour_after_opening_hour

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:name, :id) }

  def hours
    (opening_hour...closing_hour).to_a
  end

  def booked_quantity_at(starts_at)
    bookings.active.where(starts_at: starts_at).sum(:quantity)
  end

  def remaining_quantity_at(starts_at)
    capacity - booked_quantity_at(starts_at)
  end

  private

  def closing_hour_after_opening_hour
    return if opening_hour.blank? || closing_hour.blank?
    errors.add(:closing_hour, :greater_than_start_date) unless closing_hour > opening_hour
  end
end
