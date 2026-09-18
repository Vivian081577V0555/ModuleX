Rails.application.routes.draw do
  resources :projects, only: [] do
    resources :community_booking_facilities, path: 'community-booking' do
      resources :community_bookings, path: 'bookings', only: [:create, :destroy]
    end
  end
end
