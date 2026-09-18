class CommunityBookingFacilitiesController < ApplicationController
  before_action :find_project
  before_action :authorize
  before_action :find_facility, only: [:show, :edit, :update, :destroy]

  helper :projects

  def index
    @date = selected_date
    @facilities = CommunityBookingFacility.where(project_id: @project.id).sorted
    @visible_facilities = @facilities.select(&:active?)
    @visible_facilities = @facilities if @visible_facilities.empty?
    @hours = booking_hours(@visible_facilities)
    @bookings = CommunityBooking.active
                                .where(project_id: @project.id, community_booking_facility_id: @visible_facilities.map(&:id))
                                .where(starts_at: day_range(@date))
                                .includes(:user)
                                .order(:starts_at, :id)
                                .group_by { |booking| [booking.community_booking_facility_id, booking.starts_at] }
  end

  def show
    redirect_to project_community_booking_facilities_path(@project, facility_id: @facility.id)
  end

  def new
    @facility = CommunityBookingFacility.new(project: @project, capacity: 1, opening_hour: 8, closing_hour: 22, active: true)
  end

  def create
    @facility = CommunityBookingFacility.new(facility_params)
    @facility.project = @project

    if @facility.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_community_booking_facilities_path(@project, facility_id: @facility.id)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @facility.update(facility_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_community_booking_facilities_path(@project, facility_id: @facility.id)
    else
      render :edit
    end
  end

  def destroy
    @facility.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_community_booking_facilities_path(@project)
  end

  private

  def find_project
    @project = Project.find_by(identifier: params[:project_id]) || Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_facility
    @facility = CommunityBookingFacility.where(project_id: @project.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def selected_date
    Date.parse(params[:date].to_s)
  rescue ArgumentError
    User.current.today
  end

  def day_range(date)
    Time.zone.local(date.year, date.month, date.day).beginning_of_day..Time.zone.local(date.year, date.month, date.day).end_of_day
  end

  def facility_params
    params.require(:community_booking_facility).permit(:name, :description, :capacity, :opening_hour, :closing_hour, :active)
  end

  def booking_hours(facilities)
    return [] if facilities.empty?

    opening_hour = facilities.map(&:opening_hour).min
    closing_hour = facilities.map(&:closing_hour).max
    (opening_hour...closing_hour).to_a
  end
end
