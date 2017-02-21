class SessionsController < ApplicationController

  skip_before_action :logged_in_user

  def new
  end
  
  def create
    user = User.find_by(login: params[:session][:login].downcase)
    if !user
      flash.now[:danger] = 'Unknown user'
      render 'new'
    elsif !user.password_digest || user.password_digest.empty?
      flash.now[:danger] = 'User has no password'
      render 'new'
    elsif user.authenticate(params[:session][:password])
      log_in user
      redirect_to '/'
    else
      logger.info 'Authentication failed'
      flash.now[:danger] = 'Login failed'
      render 'new'
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end
end
