class CommunityBookingsController < ApplicationController
  before_action :find_project
  before_action :authorize
  before_action :find_facility
  before_action :find_booking, only: [:destroy]

  def create
    starts_at = build_slot_time
    @booking = CommunityBooking.new(
      project: @project,
      facility: @facility,
      user: User.current,
      starts_at: starts_at,
      ends_at: starts_at + 1.hour,
      quantity: booking_quantity,
      notes: params[:notes].to_s.strip,
      status: 'booked'
    )

    if @booking.save
      flash[:notice] = l(:notice_community_booking_created)
    else
      flash[:error] = @booking.errors.full_messages.to_sentence
    end

    redirect_to project_community_booking_facilities_path(@project, facility_id: @facility.id, date: starts_at.to_date)
  end

  def destroy
    unless @booking.cancellable_by?(User.current) || User.current.allowed_to?(:manage_community_booking, @project)
      deny_access
      return
    end

    @booking.update(status: 'cancelled')
    flash[:notice] = l(:notice_community_booking_cancelled)
    redirect_to project_community_booking_facilities_path(@project, facility_id: @facility.id, date: @booking.starts_at.to_date)
  end

  private

  def find_project
    @project = Project.find_by(identifier: params[:project_id]) || Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_facility
    @facility = CommunityBookingFacility.where(project_id: @project.id).find(params[:community_booking_facility_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_booking
    @booking = @facility.bookings.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_slot_time
    date = Date.parse(params[:date].to_s)
    hour = params[:hour].to_i
    raise ArgumentError unless @facility.hours.include?(hour)

    Time.zone.local(date.year, date.month, date.day, hour)
  rescue ArgumentError
    Time.zone.local(User.current.today.year, User.current.today.month, User.current.today.day, @facility.opening_hour)
  end

  def booking_quantity
    qty = params[:quantity].to_i
    qty.positive? ? qty : 1
  end
end
