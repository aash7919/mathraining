# -*- coding: utf-8 -*-
require "spec_helper"

describe "Category pages", category: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let!(:category) { FactoryBot.create(:category) }
  let(:newname) { "Nouveau nom" }

  describe "root" do
    before do
      sign_in root
      visit subjects_path
    end
    
    describe "view categories" do
      before { visit categories_path }
      it { should have_selector("h1", text: "Modifier les catégories") }
      
      describe "and modifies one" do
        before do
          page.all(:fillable_field, "category[name]").first.set(newname)
          page.all(:button, "Modifier cette catégorie").first.click
        end
        specify { expect(Category.order(:id).first.name).to eq(newname) }
      end
      
      describe "and modifies one with empty name" do
        before do
          page.all(:fillable_field, "category[name]").first.set("")
          page.all(:button, "Modifier cette catégorie").first.click
        end
        specify do
          expect(page).to have_error_message("Nom doit être rempli")
          expect(Category.order(:id).first.name).to_not eq("")
        end
      end
      
      describe "and adds one with good name" do
        before do
          page.all(:fillable_field, "category[name]").last.set(newname)
          click_button "Ajouter cette catégorie"
        end
        specify { expect(Category.order(:id).last.name).to eq(newname) }
      end
      
      describe "and adds one with empty name" do
        before do
          page.all(:fillable_field, "category[name]").last.set("")
          click_button "Ajouter cette catégorie"
        end
        specify do
          expect(page).to have_error_message("Nom doit être rempli")
          expect(Category.order(:id).last.name).to_not eq("")
        end
      end
      
      describe "and deletes one" do
        specify { expect { page.all(:link, "Supprimer cette catégorie").first.click }.to change(Category, :count).by(-1) }
      end
    end
  end
end
