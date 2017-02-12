class MachinesController < ApplicationController

  def new
    @machine = Machine.new
  end

  def edit
    @machine = Machine.find(params[:id])
  end

  def index
    @machines = Machine.all
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
