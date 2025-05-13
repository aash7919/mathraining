# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contestproblemcheck pages", contestproblem: true do

  subject { page }

  let!(:user_following_contest) { FactoryBot.create(:user) }
  let!(:user_following_subject) { FactoryBot.create(:user) }
    
  let!(:running_contest) { FactoryBot.create(:contest, status: :in_progress) }
  let!(:running_contestproblem) { FactoryBot.create(:contestproblem, contest: running_contest, number: 1, status: :not_started_yet, start_time: DateTime.now + 2.days, end_time: DateTime.now + 2.days) }
  let!(:running_contestproblemcheck) { FactoryBot.create(:contestproblemcheck, contestproblem: running_contestproblem) }
  let!(:running_contestsubject) { FactoryBot.create(:subject, contest: running_contest, category: Category.where(:name => "Mathraining").first, last_comment_time: DateTime.now - 2.days) }
  
  before do
    user_following_subject.followed_subjects << running_contestsubject
    user_following_contest.followed_contests << running_contest
  end
  
  describe "anyone" do
    before { sign_in user_following_contest }
  
    describe "visits a contest just before problem publication" do
      before do
        running_contestproblem.update_attribute(:start_time, DateTime.now + 5.minutes)
        visit contest_path(running_contest)
        running_contestproblem.reload
      end
      specify do
        expect(running_contestproblem.not_started_yet?).to eq(true)
        expect(page).to have_no_content(running_contestproblem.statement)
      end
    end
  
    describe "visits a contest just after problem publication" do
      before do
        running_contestproblem.update_attribute(:start_time, DateTime.now - 1.minute)
        visit contest_path(running_contest)
        running_contestproblem.reload
      end
      specify do
        expect(running_contestproblem.in_progress?).to eq(true)
        expect(page).to have_content(running_contestproblem.statement)
      end
    end
    
    describe "visits a contest just after problem ends" do
      before do
        running_contestproblem.in_progress!
        running_contestproblem.update(:start_time => DateTime.now - 120.minutes,
                                      :end_time   => DateTime.now - 1.minute)
        visit contest_path(running_contest)
        running_contestproblem.reload
      end
      specify do
        expect(running_contestproblem.in_correction?).to eq(true)
        expect(page).to have_content("En cours de correction")
      end
    end
  end
  
  describe "cron job" do
    describe "checks contestproblem one day before publication" do
      let!(:num_messages_before) { running_contestsubject.messages.count }
      before do
        running_contestproblem.no_reminder_sent!
        s = DateTime.now + 1.day - 2.minutes
        running_contestproblem.update(:start_time => s,
                                      :end_time   => s + 1.hour)
        Contest.check_contests_starts
        running_contestproblem.reload
        running_contestsubject.reload
      end
      specify do
        expect(running_contestproblem.early_reminder_sent?).to eq(true)
        expect(running_contestsubject.messages.count).to eq(num_messages_before + 1)
        expect(running_contestsubject.messages.order(:id).last.created_at).to eq(running_contestproblem.start_time - 1.day + running_contestproblem.number.seconds)
        expect(running_contestsubject.last_comment_time).to eq(running_contestproblem.start_time - 1.day + running_contestproblem.number.seconds)
      end
    end
    
    describe "checks contestproblem just after publication" do
      let!(:num_messages_before) { running_contestsubject.messages.count }
      before do
        running_contestproblem.early_reminder_sent!
        s = DateTime.now - 2.minutes
        running_contestproblem.update(:start_time => s,
                                      :end_time   => s + 1.hour)
        Contest.check_contests_starts
        running_contestproblem.reload
        running_contestsubject.reload
      end
      specify do
        expect(running_contestproblem.all_reminders_sent?).to eq(true)
        expect(running_contestsubject.messages.count).to eq(num_messages_before + 1)
        expect(running_contestsubject.messages.order(:id).last.created_at).to eq(running_contestproblem.start_time + running_contestproblem.number.seconds)
        expect(running_contestsubject.last_comment_time).to eq(running_contestproblem.start_time + running_contestproblem.number.seconds)
      end
    end
  end
end
