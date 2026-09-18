class CommunityBooking < ActiveRecord::Base
  STATUSES = %w[booked cancelled].freeze

  belongs_to :project
  belongs_to :facility, class_name: 'CommunityBookingFacility', foreign_key: 'community_booking_facility_id'
  belongs_to :user

  validates :starts_at, :ends_at, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :one_hour_slot
  validate :facility_capacity_available, if: -> { facility.present? && starts_at.present? && booked? }

  scope :active, -> { where(status: 'booked') }
  scope :recent, -> { order(starts_at: :desc, id: :desc) }

  def booked?
    status == 'booked'
  end

  def cancellable_by?(user)
    user.admin? || user_id == user.id
  end

  private

  def one_hour_slot
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, :invalid) unless ends_at == starts_at + 1.hour
    errors.add(:starts_at, :invalid) unless starts_at.min.zero? && starts_at.sec.zero?
  end

  def facility_capacity_available
    booked = facility.bookings.active.where(starts_at: starts_at).where.not(id: id).sum(:quantity)
    return if booked + quantity <= facility.capacity

    errors.add(:quantity, :less_than_or_equal_to, count: [facility.capacity - booked, 0].max)
  end
end
