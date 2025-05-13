#encoding: utf-8

# == Schema Information
#
# Table name: visitors
#
#  id        :integer          not null, primary key
#  date      :date
#  nb_users  :integer
#  nb_admins :integer
#
class Visitor < ActiveRecord::Base

  # VALIDATIONS
  
  validates :date, presence: true, uniqueness: true
  validates :nb_users, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nb_admins, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Compute the number of visitors for the last day (done every day at midnight (see schedule.rb))
  def self.compute
    # Get date of yesterday
    timenow = DateTime.now.in_time_zone
    if(timenow.hour == 0) # In case of ~00:00
      yesterday = timenow.to_date - 1.day
    elsif(timenow.hour == 23) # In case of ~23:59
      yesterday = timenow.to_date
    else # Strange: do not compute visitors
      return
    end
    
    # Check if already computed (strange)
    if Visitor.where(:date => yesterday).count > 0
      return
    end
    
    # Compute number of users and admins connected yesterday
    num_users = User.where(:role => :student).where("last_connexion_date >= ?", yesterday).count
    num_admins = User.where(:role => [:administrator, :root]).where("last_connexion_date >= ?", yesterday).count
    
    # Create new Visitor element
    Visitor.create(:date => yesterday, :nb_users => num_users, :nb_admins => num_admins)  
  end
end
