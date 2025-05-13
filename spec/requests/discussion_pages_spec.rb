# -*- coding: utf-8 -*-
require "spec_helper"

describe "Discussion pages", discussion: true do

  subject { page }
  
  let(:root) { FactoryBot.create(:root) }
  let(:user) { FactoryBot.create(:user) }
  let!(:other_user) { FactoryBot.create(:user, last_connexion_date: DateTime.now) } # last_connexion_date to be sure that other_user appears in the list
  let!(:other_user2) { FactoryBot.create(:user) }
  let(:content) { "Salut mon ami!" }
  let(:content2) { "Salut mon pote!" }
  let(:content3) { "Comment vas-tu?" }
  let(:content4) { "Je suis content de te parler" }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
  describe "user" do
    before { sign_in user }
    
    describe "visits new discussion page" do
      before { visit new_discussion_path }
      it { should have_selector("h3", text: "Nouvelle discussion") }
    
      describe "and creates a discussion" do
        before do
          select other_user.name, from: "qui"
          fill_in "MathInput", with: content
          click_button "Envoyer"
        end
        it do
          should have_selector("h3", text: other_user.name)
          should have_selector("div", text: content)
        end
        
        describe "and creates again the same discussion" do
          before do
            visit new_discussion_path
            select other_user.name, from: "qui"
            fill_in "MathInput", with: content2
            click_button "Envoyer"
          end
          it do
            should have_selector("div", text: content)
            should have_selector("div", text: content2)
          end
        end
        
        describe "and creates again the same discussion while the other guy answered" do
          before do
            visit new_discussion_path
            d = Discussion.order(:id).last
            Tchatmessage.create(:discussion => d, :user => other_user, :content => content3)
            Link.where(:discussion => d, :user => user).first.update_attribute(:nonread, 1)
            select other_user.name, from: "qui"
            fill_in "MathInput", with: content2
            click_button "Envoyer"
          end
          it do
            should have_error_message("Un message a été envoyé avant le vôtre.")
            should have_selector("div", text: content)
            should have_selector("div", text: content3)
          end
        end
      end
      
      describe "and creates a discussion without choosing the user" do
        before do
          fill_in "MathInput", with: content
          click_button "Envoyer"
          user.reload
        end
        specify do
          should have_error_message("Veuillez choisir un destinataire.")
          should have_selector("textarea", text: content)
          expect(user.discussions.count).to eq(0)
        end
      end
    end
    
    describe "answers to a discussion" do
      before do
        d = create_discussion_between(user, other_user, content, content2)
        visit discussion_path(d)
        fill_in "MathInput", with: content3
        click_button "Envoyer"
      end
      it { should have_selector("div", text: content3) }
    end
    
    describe "marks a discussion as unread" do
      let!(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit discussion_path(discussion)
        click_link "Marquer comme non lu"
        discussion.reload
      end
      specify do
        expect(page).to have_content("#{other_user.name} (1)")
        expect(Link.where(:user => user, :discussion => discussion).first.nonread).to eq(1)
      end
    end
    
    describe "answers to a discussion with an empty message" do
      before do
        d = create_discussion_between(user, other_user, content, content2)
        visit discussion_path(d)
        fill_in "MathInput", with: ""
        click_button "Envoyer"
      end
      it { should have_error_message("Message doit être rempli") }
    end
    
    describe "answers to a discussion while the other guy also answered" do
      before do
        d = create_discussion_between(user, other_user, content, content2)
        visit discussion_path(d)
        Tchatmessage.create(:discussion => d, :user => other_user, :content => content4)
        Link.where(:discussion => d, :user => user).first.update_attribute(:nonread, 1)
        fill_in "MathInput", with: content3
        click_button "Envoyer"
      end
      it do
        should have_error_message("Un message a été envoyé avant le vôtre.")
        should have_selector("div", text: content4)
      end
    end
    
    describe "wants to a send a message to a new guy" do
      before do
        visit user_path(other_user)
        click_link "Envoyer un message"
      end
      it do
        should have_current_path(new_discussion_path(:qui => other_user))
        should have_select("qui", selected: other_user.name)
      end
    end
    
    describe "wants to a send a message to a guy with a discussion" do
      let!(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit user_path(other_user)
        click_link "Envoyer un message"
      end
      it { should have_current_path(discussion_path(discussion)) }
    end
    
    describe "asks to receive emails for new messages" do
      before do
        visit new_discussion_path
        click_link("M'avertir des nouveaux messages par e-mail")
        user.reload
      end
      specify do
        expect(page).to have_success_message("Vous recevrez dorénavant un e-mail à chaque nouveau message privé.")
        expect(page).to have_link("Ne plus m'avertir par e-mail")
        expect(user.follow_message).to eq(true)
      end
      
      describe "and asks to not receive them anymore" do
        before do
          click_link("Ne plus m'avertir par e-mail", :match => :first)
          user.reload
        end
        specify do
          expect(page).to have_success_message("Vous ne recevrez maintenant plus d'e-mail lors d'un nouveau message privé.")
          expect(page).to have_link("M'avertir des nouveaux messages par e-mail")
          expect(user.follow_message).to eq(false)
        end
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "tries to see the messages of a user" do
      let!(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit user_path(user)
        click_link "Voir le site comme lui"
        visit discussion_path(discussion)
      end
      it do
        should have_error_message("Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un.")
        should have_no_content(discussion.tchatmessages.first.content)
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user", :js => true do
    before { sign_in user }
    
    describe "sends a tchatmessage with a file" do
      let(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit discussion_path(discussion)
        fill_in "MathInput", with: content3
        wait_for_js_imports
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image2))
        click_button "Envoyer"
      end
      let(:newtchatmessage) { discussion.tchatmessages.order(:id).last }
      specify do
        expect(newtchatmessage.content).to eq(content3)
        expect(newtchatmessage.myfiles.count).to eq(1)
        expect(newtchatmessage.myfiles.first.file.filename.to_s).to eq(image2)
      end
    end
    
    describe "sends a tchatmessage with a wrong file" do
      let(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit discussion_path(discussion)
        fill_in "MathInput", with: content3
        wait_for_js_imports
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Envoyer"
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
        should have_selector("textarea", text: content3)
      end
    end
    
    describe "creates a discussion with a wrong file" do
      before do
        visit new_discussion_path
        wait_for_js_imports
        wait_for_ajax
        select2 other_user.name, xpath: '//div[@id="destinataire-div"]' # NB: from: "destinataire" does not work
        fill_in "MathInput", with: content
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Envoyer"
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
        should have_selector("textarea", text: content)
      end
    end
    
    describe "visits a long discussion" do
      let!(:discussion) { create_discussion_between(user, other_user, content, content2) }
      let(:long_content) { "Ce texte est un peu long.\n\nMais j'ai beaucoup de choses à dire\n\nComment vas-tu?\n\nTest " }
      before do
        (1..25).each do |i|
          Tchatmessage.create(:discussion => discussion, :user => (i % 2 == 1 ? user : other_user), :content => long_content + i.to_s)
        end
        visit discussion_path(discussion)
      end
      it do
        should have_content(long_content + "25")
        should have_no_content(long_content + "15")
        should have_no_content(long_content + "5")
      end
      
      describe "and scrolls to the bottom" do
        before do
          visit discussion_path(discussion, :anchor => "footer")
          wait_for_js_imports # Not sure this is a good solution for this case
          wait_for_ajax
        end
        it do
          should have_content(long_content + "25")
          should have_content(long_content + "15")
          #should have_no_content(long_content + "5") # Deactivated because it seems to fail randomly
        end
      end
    end
    
    describe "has more than 5 discussions", :js => false do
      let!(:other_user3) { FactoryBot.create(:user) }
      let!(:other_user4) { FactoryBot.create(:user) }
      let!(:other_user5) { FactoryBot.create(:user) }
      let!(:discussion_1) { create_discussion_between(user, root, content, content2) }
      let!(:discussion_2) { create_discussion_between(user, other_user, content, content2) }
      let!(:discussion_3) { create_discussion_between(user, other_user2, content, content2) }
      let!(:discussion_4) { create_discussion_between(user, other_user3, content, content2) }
      let!(:discussion_5) { create_discussion_between(user, other_user4, content, content2) }
      let!(:discussion_6) { create_discussion_between(user, other_user5, content, content2) }
      
      before { visit new_discussion_path }
      it do
        should have_no_content(root.name) # Not shown yet because 6th in the list
        should have_content(other_user.name)
        should have_content(other_user2.name)
        should have_content(other_user3.name)
        should have_content(other_user4.name)
        should have_content(other_user5.name)
        should have_button("Tout charger")
      end
      
      describe "and click to show all of them", :js => true do
        before do
          click_button "Tout charger"
          wait_for_ajax
        end
        it do
          should have_content(root.name) # Should now be shown
          should have_content(other_user.name)
          should have_content(other_user2.name)
          should have_content(other_user3.name)
          should have_content(other_user4.name)
          should have_content(other_user5.name)
          should have_no_button("Tout charger")
        end
      end
    end
  end
end
