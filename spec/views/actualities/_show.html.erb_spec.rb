# -*- coding: utf-8 -*-
require "spec_helper"

describe "actualities/_show.html.erb", type: :view, actuality: true do
  
  subject { rendered }
  
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let!(:actuality) { FactoryBot.create(:actuality) }
  
  before { assign(:actualities, Actuality.paginate(:page => 1, :per_page => 5)) }
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    it "renders the actuality and the modify/delete links" do
      render partial: "actualities/index"
      should have_content(actuality.title)
      should have_content(actuality.content)
      should have_link("Modifier l'actualité")
      should have_link("Supprimer l'actualité")
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    it "renders the actuality and not the modify/delete links" do
      render partial: "actualities/index"
      should have_content(actuality.title)
      should have_content(actuality.content)
      should have_no_link("Modifier l'actualité")
      should have_no_link("Supprimer l'actualité")
    end
  end
  
  context "if the user is not signed in" do
    it "renders the actuality and not the modify/delete links" do
      render partial: "actualities/index"
      should have_content(actuality.title)
      should have_content(actuality.content)
      should have_no_link("Modifier l'actualité")
      should have_no_link("Supprimer l'actualité")
    end
  end
end
