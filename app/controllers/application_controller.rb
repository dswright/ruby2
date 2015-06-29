class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  require 'rails_autolink'
  require 'uri'
  #these have to be included in this file to have access to the helper files in the controller.
  include SessionsHelper
  include StocksHelper
  include CommentsHelper
  include StreamsHelper
  include PredictionsHelper
  include FeedsHelper
  include ReferralsHelper
  
  
end
