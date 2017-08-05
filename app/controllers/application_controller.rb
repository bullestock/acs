class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :logged_in_user
  skip_before_action :logged_in_user, only: [ :index, :login ]
  
  include SessionsHelper

  # Confirms a logged-in user.
  def logged_in_user
    unless logged_in?
      flash[:danger] = "Please log in."
      redirect_to login_url
    end
  end

  def admin_user
    unless logged_in? && @current_user.permissions.map(&:name).include?('admin')
      flash[:danger] = "You are not allowed to access this page."
      redirect_to '/'
    end
  end

  def provisioning_user
    unless logged_in? && (@current_user.permissions.map(&:name).include?('admin') ||
                          @current_user.permissions.map(&:name).include?('provision'))
      flash[:danger] = "You are not allowed to access this page."
      redirect_to '/'
    end
  end
end
