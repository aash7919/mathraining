# -*- coding: utf-8 -*-
require "spec_helper"

describe "privacypolicies/show.html.erb", type: :view, privacypolicy: true do

  subject { rendered }

  let(:root) { FactoryBot.create(:root) }
  let(:user) { FactoryBot.create(:user) }
  let!(:privacypolicy1) { FactoryBot.create(:privacypolicy, publication_time: DateTime.now - 100.days, online: true) }
  let!(:privacypolicy2) { FactoryBot.create(:privacypolicy, publication_time: DateTime.now - 50.days, online: true) }
  let!(:privacypolicy3) { FactoryBot.create(:privacypolicy, publication_time: DateTime.now - 10.days, online: true) }
  let!(:privacypolicy4) { FactoryBot.create(:privacypolicy, online: false) }
  
  context "if the user is a root" do
    before do
      sign_in_view(root)
      assign(:privacypolicy, privacypolicy3)
    end
    
    it "renders the update button" do
      render template: "privacypolicies/show"
      should have_link("Mettre à jour la politique de confidentialité")
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    context "if this is the first version " do
      before { assign(:privacypolicy, privacypolicy1) }
      
      it "renders the privacypolicy correctly and not the update buttons" do
        render template: "privacypolicies/show"
        should have_selector("b", text: "Version du #{write_date_only(privacypolicy1.publication_time)}")
        should have_link("Version du #{write_date_only(privacypolicy2.publication_time)}", href: privacypolicy_path(privacypolicy2))
        should have_no_text("(dernière version)")
        should have_content(privacypolicy1.content)
        should have_no_link("Mettre à jour la politique de confidentialité")
      end
    end
    
    context "if this is the second version " do
      before { assign(:privacypolicy, privacypolicy2) }
      
      it "renders the privacypolicy correctly and not the update buttons" do
        render template: "privacypolicies/show"
        should have_link("Version du #{write_date_only(privacypolicy1.publication_time)}", href: privacypolicy_path(privacypolicy1))
        should have_selector("b", text: "Version du #{write_date_only(privacypolicy2.publication_time)}")
        should have_link("Version du #{write_date_only(privacypolicy3.publication_time)}", href: privacypolicy_path(privacypolicy3))
        should have_no_text("(dernière version)")
        should have_content(privacypolicy2.content)
      end
    end
    
    context "if this is the last (online) version " do
      before { assign(:privacypolicy, privacypolicy3) }
      
      it "renders the privacypolicy correctly and not the update buttons" do
        render template: "privacypolicies/show"
        should have_link("Version du #{write_date_only(privacypolicy2.publication_time)}", href: privacypolicy_path(privacypolicy2))
        should have_selector("b", text: "Version du #{write_date_only(privacypolicy3.publication_time)}")
        should have_text("(dernière version)")
        should have_content(privacypolicy3.content)
      end
    end
  end
end
