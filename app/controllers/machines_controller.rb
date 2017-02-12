class MachinesController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper
  before_action :logged_in_user

  def new
    @machine = Machine.new
  end

  def edit
    @machine = Machine.find(params[:id])
  end

  def index
    @users = smart_listing_create :machines, Machine.all, partial: "machines/list", page_sizes: [10000],
                                  sort_attributes: [[:name, "name"]],
                                  default_sort: {name: "asc"}
  end
  
  def show
    @machine = Machine.find(params[:id])
  end
  
  def create
    @machine = Machine.new(machine_params)

    @machine.save
    redirect_to @machine
  end

  def update
    @machine = Machine.find(params[:id])

    if @machine.update(machine_params)
      redirect_to action: "index"
    else
      render 'edit'
    end
  end

  def destroy
    Machine.find(params[:id]).destroy
    flash[:success] = "Machine deleted"
    redirect_to machine_url
  end
  
  private
  def machine_params
    params.require(:machine).permit(:name)
  end
end
