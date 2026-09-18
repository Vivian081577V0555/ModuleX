require 'redmine'

Redmine::Plugin.register :redmine_community_booking do
  name 'Redmine Community Booking'
  author 'ModuleX'
  description 'Project-level facility booking with hourly capacity calendar.'
  version '0.1.0'

  project_module :community_booking do
    permission :view_community_booking, community_booking_facilities: [:index, :show]
    permission :book_community_facilities, community_bookings: [:create, :destroy]
    permission :manage_community_booking, community_booking_facilities: [:new, :create, :edit, :update, :destroy],
                                          community_bookings: [:destroy]
  end

  menu :project_menu,
       :community_booking,
       { controller: 'community_booking_facilities', action: 'index' },
       caption: :label_community_booking,
       after: :community_finance,
       param: :project_id
end
