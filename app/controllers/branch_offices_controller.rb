class BranchOfficesController < ApplicationController

  before_action :authenticate_staff!, :except => [:get_by_location]
  before_action :set_branch_office, only: [:update_attention_types_estimations]

  def pundit_user
    current_staff
  end


  def index
  end

  #
  # Recibe un arreglo con las estimaciones que esta sucursal le da a cada tipo de atencion.
  # y los actualiza para esta sucursal.
  #
  # PUT /branch_offices/:id/attention_types
  # Ejemplo de uso
  # {
  #	"duration_estimations": [
  #		{ "attention_type_id": 1 , "duration": 30},
  #		{ "attention_type_id": 2 , "duration": 45},
  #		{ "attention_type_id": 3 , "duration": 15}
  #		]
  #  }
  #
  def update_attention_types_estimations

    authorize @branch_office

    duration_estimations = params[:duration_estimations]

    ActiveRecord::Base.transaction do
      DurationEstimation.where(branch_office_id: @branch_office.id).delete_all
      duration_estimations.each do |est|
        @branch_office.duration_estimations << DurationEstimation.new(
          :attention_type_id => est[:attention_type_id],
          :duration => est[:duration])
      end
    end

    render :json => {}, :status => :ok

  end



  def get_by_location

    regions = Hash.new

    offices = BranchOffice.all.includes({ :comuna => :region })

    offices.each do |o|
      comuna = o.comuna.name
      region = o.comuna.region.name
      address = o.address
      if !regions.has_key? region
        regions[region] = {}
      end
      if !regions[region].has_key? comuna
        regions[region][comuna] = []
      end
      regions[region][comuna] << { address: address, id: o.id }
    end

    render :json => regions.as_json, :status => :ok

  end


  private

  def set_branch_office
    @branch_office = BranchOffice.find(params[:id])
  end



end
