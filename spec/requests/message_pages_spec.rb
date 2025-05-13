# -*- coding: utf-8 -*-
require "spec_helper"

describe "Message pages", message: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:other_root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:other_admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }

  let!(:sub) { FactoryBot.create(:subject) }
  let!(:sub2) { FactoryBot.create(:subject) }

  let!(:mes) { FactoryBot.create(:message, subject: sub) }
  let!(:mes_user) { FactoryBot.create(:message, user: user, subject: sub) }
  let!(:mes_admin) { FactoryBot.create(:message, user: admin, subject: sub) }
  let!(:mes_other_admin) { FactoryBot.create(:message, user: other_admin, subject: sub) }
  let!(:mes_other_root) { FactoryBot.create(:message, user: other_root, subject: sub2) }
  
  let(:content) { "Ma belle réponse" }
  let(:content2) { "Ma nouvelle réponse" }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
  describe "user" do
    before { sign_in user }
    
    describe "visits a subject" do
      before { visit subject_path(sub) }
      it do
        should have_link("LinkEditMessage#{mes_user.id}")
        should have_no_link("LinkDeleteMessage#{mes_user.id}")
        should have_button("SubmitMessage#{mes_user.id}")
        should have_no_link("LinkEditMessage#{mes.id}")
        should have_no_button("SubmitMessage#{mes.id}")
        should have_button("Répondre")
        should have_button("Poster")
      end
      
      describe "and edits his message" do
        before do
          fill_in "MathInputMessage#{mes_user.id}", with: content
          click_button "SubmitMessage#{mes_user.id}"
          mes_user.reload
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été modifié.")
          expect(mes_user.content).to eq(content)
        end
      end
      
      describe "and edits his message with an empty one" do
        before do
          fill_in "MathInputMessage#{mes_user.id}", with: ""
          click_button "SubmitMessage#{mes_user.id}"
          mes_user.reload
        end
        specify do
          expect(page).to have_error_message("Message doit être rempli")
          expect(mes_user.content).not_to eq("")
        end
      end
      
      describe "and soft deletes his message" do
        before do
          click_link "LinkSoftDeleteMessage#{mes_user.id}"
          mes_user.reload
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été supprimé.")
          expect(page).to have_content("Ce message a été supprimé.")
          expect(mes_user.erased).to eq(true)
        end
      end
      
      describe "and writes a new message" do
        before do
          fill_in "MathInputNewMessage", with: content2
          click_button "Poster"
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été posté.")
          expect(sub.messages.order(:id).last.content).to eq(content2)
        end
      end
      
      describe "and writes a new message while somebody else wrote a message" do
        before do
          FactoryBot.create(:message, user: admin, subject: sub)
          fill_in "MathInputNewMessage", with: content2
          click_button "Poster"
        end
        specify do
          expect(page).to have_error_message("Un nouveau message a été posté avant le vôtre")
          expect(sub.messages.order(:id).last.content).not_to eq(content2)
        end
      end
      
      describe "and writes an empty message" do
        before do
          fill_in "MathInputNewMessage", with: ""
          click_button "Poster"
        end
        specify do
          expect(page).to have_error_message("Message doit être rempli")
          expect(sub.messages.order(:id).last.content).not_to eq("")
        end
      end
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "visits the subject" do
      before { visit subject_path(sub) }
      it do
        should have_link("LinkEditMessage#{mes.id}")
        should have_link("LinkDeleteMessage#{mes.id}")
        should have_button("SubmitMessage#{mes.id}")
        should have_link("LinkEditMessage#{mes_admin.id}")
        should have_link("LinkDeleteMessage#{mes_admin.id}")
        should have_button("SubmitMessage#{mes_admin.id}")
        should have_no_link("LinkEditMessage#{mes_other_admin.id}")
        should have_no_link("LinkDeleteMessage#{mes_other_admin.id}")
        should have_no_button("SubmitMessage#{mes_other_admin.id}")
      end
      
      specify { expect { click_link("LinkDeleteMessage#{mes.id}") }.to change(Message, :count).by(-1).and change(Subject, :count).by(0) }
      specify {	expect { click_link("LinkDeleteMessage#{mes_admin.id}") }.to change(Message, :count).by(-1).and change(Subject, :count).by(0) }
      
      describe "and edits the message of a student" do
        before do
          fill_in "MathInputMessage#{mes.id}", with: content
          click_button "SubmitMessage#{mes.id}"
          mes.reload
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été modifié.")
          expect(mes.content).to eq(content)
        end
      end
      
      describe "and edits his own message" do
        before do
          fill_in "MathInputMessage#{mes_admin.id}", with: content
          click_button "SubmitMessage#{mes_admin.id}"
          mes_admin.reload
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été modifié.")
          expect(mes_admin.content).to eq(content)
        end
      end
      
      describe "and soft deletes the message of a student" do
        let!(:messagemyfile) { FactoryBot.create(:messagemyfile, myfiletable: mes) }
        before do
          click_link "LinkSoftDeleteMessage#{mes.id}"
          mes.reload
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été supprimé.")
          expect(page).to have_content("Ce message a été supprimé.")
          expect(mes.erased).to eq(true)
          expect(mes.myfiles.count).to eq(0)
          expect(mes.fakefiles.count).to eq(1) # Files are automatically fake deleted
        end
      end
    end
  end

  describe "root" do
    before { sign_in root }
    
    describe "visits the subject" do
      before { visit subject_path(sub2) }
      it do
        should have_link("LinkEditMessage#{mes_other_root.id}")
        should have_link("LinkDeleteMessage#{mes_other_root.id}")
        should have_button("SubmitMessage#{mes_other_root.id}")
      end
      
      specify { expect { click_link("LinkDeleteMessage#{mes_other_root.id}") }.to change(Message, :count).by(-1).and change(Subject, :count).by(-1) } # because we delete the only message
      
      describe "and edits the message of another root" do
        before do
          fill_in "MathInputMessage#{mes_other_root.id}", with: content
          click_button "SubmitMessage#{mes_other_root.id}"
          mes_other_root.reload
        end
        specify do
          expect(page).to have_success_message("Votre message a bien été modifié.")
          expect(mes_other_root.content).to eq(content)
        end
      end
    end
    
    describe "mistakenly sends a message while in the skin of someone" do # Can happen with multiple tabs
      before do
        visit subject_path(sub)
        root.update_attribute(:skin, user.id)
        fill_in "MathInputNewMessage", with: content2
        click_button "Poster"
      end
      specify do
        expect(page).to have_error_message("Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un.")
        expect(sub.messages.order(:id).last.content).not_to eq(content2)
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user", :js => true do
    before { sign_in user }
    
    describe "creates a message with two files" do
      before do
        visit subject_path(sub)
        wait_for_js_imports
        click_button "Répondre"
        wait_for_ajax
        fill_in "MathInputNewMessage", with: content
        click_button "addFileNewMessage" # Ajouter une pièce jointe
        wait_for_ajax
        attach_file("fileNewMessage_1", File.absolute_path(attachments_folder + image1))
        click_button "addFileNewMessage" # Ajouter une pièce jointe
        wait_for_ajax
        attach_file("fileNewMessage_2", File.absolute_path(attachments_folder + image2))
        click_button "Poster"
      end
      let(:newmessage) { sub.messages.order(:created_at).last }
      specify do
        expect(newmessage.content).to eq(content)
        expect(newmessage.myfiles.count).to eq(2)
        expect(newmessage.myfiles.first.file.filename.to_s).to eq(image1)
        expect(newmessage.myfiles.second.file.filename.to_s).to eq(image2)
      end
    end
    
    describe "adds a file to a message with a file" do
      let!(:messagemyfile) { FactoryBot.create(:messagemyfile, myfiletable: mes_user) }
      before do
        visit subject_path(sub)
        wait_for_js_imports
        click_link("LinkEditMessage#{mes_user.id}")
        wait_for_ajax
        fill_in "MathInputMessage#{mes_user.id}", with: content2
        click_button "addFileMessage#{mes_user.id}" # Ajouter une pièce jointe
        wait_for_ajax
        attach_file("fileMessage#{mes_user.id}_1", File.absolute_path(attachments_folder + image2))
        click_button "Modifier"
        mes_user.reload
      end
      specify do
        expect(mes_user.content).to eq(content2)
        expect(mes_user.myfiles.count).to eq(2)
        expect(mes_user.myfiles.first.file.filename.to_s).to eq(image1)
        expect(mes_user.myfiles.second.file.filename.to_s).to eq(image2)
      end
    end
    
    describe "modifies a message with a fake file" do
      let!(:messagemyfile) { FactoryBot.create(:messagemyfile, myfiletable: mes_user) }
      before do
        messagemyfile.fake_del
        visit subject_path(sub)
        wait_for_js_imports
        click_link("LinkEditMessage#{mes_user.id}")
        wait_for_ajax
        fill_in "MathInputMessage#{mes_user.id}", with: content2
        uncheck "prevFakeFileMessage#{mes_user.id}_#{Fakefile.order(:id).last.id}"
        click_button "addFileMessage#{mes_user.id}" # Ajouter une pièce jointe
        wait_for_ajax
        attach_file("fileMessage#{mes_user.id}_1", File.absolute_path(attachments_folder + image2))
        click_button "Modifier"
        mes_user.reload
      end
      specify do
        expect(mes_user.content).to eq(content2)
        expect(mes_user.fakefiles.count).to eq(0)
        expect(mes_user.myfiles.count).to eq(1)
        expect(mes_user.myfiles.first.file.filename.to_s).to eq(image2)
      end
    end
  end
end
