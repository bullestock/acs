class UsersController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper
  before_action :provisioning_user
  
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
    users_scope = User.all_with_filter(params, User.where(active: 1))

    @users = smart_listing_create :users, users_scope, partial: "users/list", page_sizes: [10000],
                                  sort_attributes: [[:fl_id, "fl_id"], [:name, "name"]],
                                  default_sort: {name: "asc"}
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
      card_id = @user.card_id
      sp_pos = card_id.index(' ')
      if sp_pos
        card_id = card_id[0..sp_pos]
      end
      # Remove card ID from unknown_cards
      uc = UnknownCard.find_by_card_id(card_id)
      if uc
        uc.destroy
      end
      flash[:success] = "User updated"
      render 'edit'
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :login, :card_id, :password, :password_confirmation, permission_ids:[], machine_ids:[])
  end
end
