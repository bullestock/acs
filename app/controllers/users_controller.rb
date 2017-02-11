class UsersController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper
  
  http_basic_authenticate_with name: "torsten", password: "secret"

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def index
    # Apply the search control filter.
    filter_params = params[:filter]
    if filter_params
      filter_params = { 'name' => { 'idx' => { 'o' => 'like', 'v' => filter_params } } }
      params[:filter] = filter_params
    end
    users_scope = User.all_with_filter(params, User.all)

    @users = smart_listing_create :users, users_scope, partial: "users/list", page_sizes: [10000],
                                  sort_attributes: [[:fl_id, "fl_id"], [:name, "name"]]
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def create
    @user = User.new(user_params)

    @user.save
    redirect_to @user
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      redirect_to action: "index"
    else
      render 'edit'
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :can_login, :can_provision, :can_deprovision, machine_ids:[])
  end
end
