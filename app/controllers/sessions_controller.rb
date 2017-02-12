class SessionsController < ApplicationController
  def new
  end
  def create
    user = User.find_by(login: params[:session][:login].downcase)
    if !user
      flash.now[:danger] = 'Unknown user'
      render 'new'
    elsif !user.password_digest || user.password_digest.empty?
      if !user.email || user.email.empty?
        flash.now[:danger] = 'User has no email'
        render 'new'
      else
        # Send one.time password by mail
        
      end
    elsif user.authenticate(params[:session][:password])
      # Log the user in and redirect to the user index.
      log_in user
      redirect_to '/users'
    else
      # Create an error message.
      flash.now[:danger] = 'Invalid email/password combination' # Not quite right!
      render 'new'
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end
end
