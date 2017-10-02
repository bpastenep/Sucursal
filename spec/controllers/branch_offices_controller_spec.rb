require 'rails_helper'

RSpec.describe BranchOfficesController, type: :controller do

  before(:each) do
    FactoryGirl.create(:attention_type)
    FactoryGirl.create(:attention_type)
    FactoryGirl.create(:attention_type)
    FactoryGirl.create(:attention_type)
    FactoryGirl.create(:attention_type)
    FactoryGirl.create(:attention_type)
  end


  describe "modificacion de las estimaciones que le da una sucursal a un tipo de atencion" do

      it "reemplaza la lista de estimaciones correctamente" do

        staff = FactoryGirl.create(:staff, :supervisor)
        sign_in staff

        # Creo dos listas de estimaciones, con distinto largo, y una ID de atencion igual en ambas listas
        est1 = [{ "attention_type_id": 1 , "duration": 30}, { "attention_type_id": 2 , "duration": 15},
    		{ "attention_type_id": 3 , "duration": 15}]

        est2 = [{ "attention_type_id": 3 , "duration": 30}, { "attention_type_id": 5 , "duration": 45}]

        branch_office = BranchOffice.find(staff.branch_office_id)
        expect(branch_office.duration_estimations.length).to eq 0

        # Hacer la primera actualizacion
        put :update_attention_types_estimations, params: { :id => branch_office.id, :duration_estimations => est1 }
        expect(response).to have_http_status(:ok)
        branch_office.reload
        expect(branch_office.duration_estimations.length).to eq 3
        expect(branch_office.duration_estimations[0].attention_type_id).to eq 1
        expect(branch_office.duration_estimations[1].attention_type_id).to eq 2
        expect(branch_office.duration_estimations[2].attention_type_id).to eq 3
        expect(DurationEstimation.count).to eq 3

        # Hacer la segunda actualizacion
        put :update_attention_types_estimations, params: { :id => branch_office.id, :duration_estimations => est2 }
        expect(response).to have_http_status(:ok)
        branch_office.reload
        expect(branch_office.duration_estimations.length).to eq 2
        expect(branch_office.duration_estimations[0].attention_type_id).to eq 3
        expect(branch_office.duration_estimations[0].duration).to eq 30
        expect(branch_office.duration_estimations[1].attention_type_id).to eq 5
        expect(branch_office.duration_estimations[1].duration).to eq 45

        # Se borran las 3 anteriores y solo quedan 2
        expect(DurationEstimation.count).to eq 2

      end

    end

end
