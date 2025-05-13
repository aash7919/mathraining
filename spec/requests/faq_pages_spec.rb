# -*- coding: utf-8 -*-
require "spec_helper"

describe "Faq pages", faq: true do

  subject { page }

  let(:admin) { FactoryBot.create(:admin) }
  let!(:faq) { FactoryBot.create(:faq, position: 1) }
  let(:newquestion) { "Nouvelle question" }
  let(:newanswer) { "Nouvelle réponse" }

  describe "visitor" do
    describe "visits faq path" do
      before { visit faqs_path }
      it do
        should have_content("Questions fréquemment posées")
        should have_content(faq.question)
        should have_content(faq.answer)
        should have_no_link("Modifier la question")
        should have_no_link("Supprimer la question")
        should have_no_link("Ajouter une question")
      end
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits faq path" do
      before { visit faqs_path }
      specify do
        expect(page).to have_content("Questions fréquemment posées")
        expect(page).to have_content(faq.question)
        expect(page).to have_content(faq.answer)
        expect(page).to have_link("Modifier la question", href: edit_faq_path(faq))
        expect(page).to have_link("Supprimer la question")
        expect(page).to have_no_link("haut") # Because only one question
        expect(page).to have_no_link("bas") # Because only one question
        expect(page).to have_link("Ajouter une question")
        expect { click_link("Supprimer la question") }.to change(Faq, :count).by(-1)
      end
    end
    
    describe "visits faq path with 2 questions" do
      let!(:faq2) { FactoryBot.create(:faq, question: "Ma question", answer: "Ma réponse", position: 2) }
      before { visit faqs_path }
      specify do
        expect(page).to have_link("bas", href: order_faq_path(faq, :new_position => 2))
        expect(page).to have_link("haut", href: order_faq_path(faq2, :new_position => 1))
      end
      
      describe "and move first question down" do
        before do
          click_link("bas")
          faq.reload
          faq2.reload
        end
        specify do
          expect(page).to have_success_message("Question déplacée vers le bas")
          expect(faq.position).to eq(2)
          expect(faq2.position).to eq(1)
        end
      end
      
      describe "and move second question up" do
        before do
          click_link("haut")
          faq.reload
          faq2.reload
        end
        specify do
          expect(page).to have_success_message("Question déplacée vers le haut")
          expect(faq.position).to eq(2)
          expect(faq2.position).to eq(1)
        end
      end
    end
    
    describe "creates a question" do
      before { visit new_faq_path }
      it { should have_selector("h1", text: "Ajouter une question") }
      
      describe "and sends with good information" do
        before do
          fill_in "Question", with: newquestion
          fill_in "MathInput", with: newanswer
          click_button "Créer"
        end
        specify do
          expect(page).to have_success_message("Question ajoutée")
          expect(Faq.order(:id).last.question).to eq(newquestion)
          expect(Faq.order(:id).last.answer).to eq(newanswer)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Question", with: newquestion
          fill_in "MathInput", with: ""
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("Réponse doit être rempli")
          expect(page).to have_selector("h1", text: "Ajouter une question")
          expect(Faq.order(:id).last.question).to_not eq(newquestion)
        end
      end
    end
    
    describe "edits a question" do
      before { visit edit_faq_path(faq) }
      it { should have_selector("h1", text: "Modifier une question") }
      
      describe "and sends with good information" do
        before do
          fill_in "Question", with: newquestion
          fill_in "MathInput", with: newanswer
          click_button "Modifier"
          faq.reload
        end
        specify do
          expect(page).to have_success_message("Question modifiée")
          expect(faq.question).to eq(newquestion)
          expect(faq.answer).to eq(newanswer)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Question", with: ""
          fill_in "MathInput", with: newanswer
          click_button "Modifier"
          faq.reload
        end
        specify do
          expect(page).to have_error_message("Question doit être rempli")
          expect(page).to have_selector("h1", text: "Modifier une question")
          expect(faq.answer).to_not eq(newanswer)
        end
      end
    end
  end
end
