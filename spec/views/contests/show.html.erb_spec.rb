# -*- coding: utf-8 -*-
require "spec_helper"

describe "contests/show.html.erb", type: :view, contest: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_bad) { FactoryGirl.create(:user, rating: 0) }
  let(:user) { FactoryGirl.create(:advanced_user) }
  let(:user_organizer) { FactoryGirl.create(:user) }
  let(:contest) { FactoryGirl.create(:contest, medal: true) }
  let(:contestproblem1) { FactoryGirl.create(:contestproblem, contest: contest) }
  let(:contestproblem2) { FactoryGirl.create(:contestproblem, contest: contest) }
  
  before do
    contest.organizers << user_organizer
    assign(:contest, contest)
  end
  
  context "if the contest is in construction" do
    before do
      contest.in_construction!
      contestproblem1.in_construction!
      contestproblem2.in_construction!
    end
    
    context "if the user is an admin" do
      before do
        assign(:current_user, admin)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_content("Organisateur du concours :")
        expect(rendered).to have_link(user_organizer.name, href: user_path(user_organizer))
        expect(rendered).to have_link("supprimer")
        expect(rendered).to have_button("Ajouter")
        expect(rendered).to have_no_link("Définir les médailles")
        expect(rendered).to have_no_link("Problèmes", href: contest_path(contest))
        expect(rendered).to have_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
        expect(rendered).to have_link("Modifier ce concours")
        expect(rendered).to have_no_link("Ajouter un problème")
        expect(rendered).to have_link("Mettre ce concours en ligne")
        expect(rendered).to have_link("Supprimer ce concours")
      end
    end
    
    context "if the user is an organizer" do
      before do
        assign(:current_user, user_organizer)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_content("Organisateur du concours :")
        expect(rendered).to have_link(user_organizer.name, href: user_path(user_organizer))
        expect(rendered).to have_no_link("supprimer")
        expect(rendered).to have_no_button("Ajouter")
        expect(rendered).to have_no_link("Définir les médailles")
        expect(rendered).to have_no_link("Problèmes", href: contest_path(contest))
        expect(rendered).to have_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
        expect(rendered).to have_link("Modifier ce concours")
        expect(rendered).to have_link("Ajouter un problème")
        expect(rendered).to have_no_link("Mettre ce concours en ligne")
        expect(rendered).to have_no_link("Supprimer ce concours")
      end
    end
  end
  
  context "if the contest is in progress" do
    before do
      contest.in_progress!
      contestproblem1.in_progress!
      contestproblem2.not_started_yet!
    end
    
    context "if the user is an admin" do
      before do
        assign(:current_user, admin)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_no_link("supprimer")
        expect(rendered).to have_no_button("Ajouter")
        expect(rendered).to have_no_link("Définir les médailles")
        expect(rendered).to have_no_link("Problèmes", href: contest_path(contest))
        expect(rendered).to have_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
        expect(rendered).to have_link("Modifier ce concours")
        expect(rendered).to have_no_link("Ajouter un problème")
        expect(rendered).to have_no_link("Mettre ce concours en ligne")
        expect(rendered).to have_no_link("Supprimer ce concours")
      end
    end
    
    context "if the user is an organizer" do
      before do
        assign(:current_user, user_organizer)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_no_link("Définir les médailles")
        expect(rendered).to have_no_link("Problèmes", href: contest_path(contest))
        expect(rendered).to have_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
        expect(rendered).to have_link("Modifier ce concours")
        expect(rendered).to have_no_link("Ajouter un problème")
      end
    end
    
    context "if the user can participate" do
      before do
        assign(:current_user, user)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_no_link("Problèmes", href: contest_path(contest))
        expect(rendered).to have_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
        expect(rendered).to have_no_link("Modifier ce concours")
      end
      
      it "renders the page correctly with tab = 1" do
        render template: "contests/show", locals: {params: {tab: 1}}
        expect(response).to render_template(:partial => "contests/_problems") # Tab 1 not accessible
      end
      
      it "renders the page correctly with tab = 2" do
        render template: "contests/show", locals: {params: {tab: 2}}
        expect(response).to render_template(:partial => "contests/_problems") # Tab 2 not accessible
      end
    end
  end
  
  context "if the contest is more in progress" do
    before do
      contest.in_progress!
      contestproblem1.corrected!
      contestproblem2.in_progress!
    end
    
    context "if the user can participate" do
      before do
        assign(:current_user, user)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_link("Problèmes", href: contest_path(contest), class: "active")
        expect(rendered).to have_link("Classement après 1 problème", href: contest_path(contest, :tab => 1))
        expect(rendered).to have_no_link("Statistiques", href: contest_path(contest, :tab => 2))
        expect(rendered).to have_no_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
      end
      
      it "renders the page correctly with tab = 1" do
        render template: "contests/show", locals: {params: {tab: 1}}
        expect(rendered).to have_link("Classement après 1 problème", href: contest_path(contest, :tab => 1), class: "active")
        expect(response).to render_template(:partial => "contests/_results")
      end
      
      it "renders the page correctly with tab = 2" do
        render template: "contests/show", locals: {params: {tab: 2}}
        expect(rendered).to have_link("Problèmes", href: contest_path(contest), class: "active")
        expect(response).to render_template(:partial => "contests/_problems") # Tab 2 not accessible
      end
    end
  end
  
  context "if the contest is corrected" do
    before do
      contest.completed!
      contestproblem1.corrected!
      contestproblem2.corrected!
    end
    
    context "if the user is an organizer" do
      before do
        assign(:current_user, user_organizer)
      end
        
      it "renders the page correctly" do
        render template: "contests/show"
        expect(rendered).to have_link("Définir les médailles")
        expect(rendered).to have_link("Problèmes", href: contest_path(contest), class: "active")
        expect(rendered).to have_link("Classement final", href: contest_path(contest, :tab => 1))
        expect(rendered).to have_link("Statistiques", href: contest_path(contest, :tab => 2))
        expect(rendered).to have_no_selector("h3", text: "Problèmes")
        expect(response).to render_template(:partial => "contests/_problems")
      end
      
      it "renders the page correctly with tab = 1" do
        render template: "contests/show", locals: {params: {tab: 1}}
        expect(rendered).to have_link("Classement final", href: contest_path(contest, :tab => 1), class: "active")
        expect(response).to render_template(:partial => "contests/_results")
      end
      
      it "renders the page correctly with tab = 2" do
        render template: "contests/show", locals: {params: {tab: 2}}
        expect(rendered).to have_link("Statistiques", href: contest_path(contest, :tab => 2), class: "active")
        expect(response).to render_template(:partial => "contests/_statistics")
      end
    end
  end
end
