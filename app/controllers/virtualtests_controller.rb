#encoding: utf-8
class VirtualtestsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online, :begin_test]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy, :put_online, :destroy]
  before_action :non_admin_user, only: [:begin_test]
  
  before_action :get_virtualtest, only: [:show, :edit, :update, :destroy, :begin_test, :put_online]
  
  before_action :online_virtualtest, only: [:begin_test]
  before_action :user_can_see_virtualtest, only: [:begin_test]
  before_action :user_can_write_submission, only: [:begin_test]
  before_action :user_can_begin_virtualtest, only: [:begin_test]
  before_action :virtualtest_can_be_online, only: [:put_online]
  before_action :offline_virtualtest, only: [:destroy]
  before_action :user_in_test, only: [:show]

  # Show all virtualtests (that can be seen)
  def index
  end

  # Show one virtualtest
  def show
    if params.has_key?(:p)
      @problem = Problem.find_by_id(params[:p].to_i)
      @problem = nil if @problem.virtualtest_id != @virtualtest.id
      unless @problem.nil?
        @submission = Submission.where(user_id: current_user.id, problem_id: @problem.id, intest: true).first
        @submission = Submission.new if @submission.nil?
      end 
    end
  end

  # Create a virtualtest (show the form)
  def new
    @virtualtest = Virtualtest.new
  end

  # Update a virtualtest (show the form)
  def edit
  end

  # Create a virtualtest (send the form)
  def create
    @virtualtest = Virtualtest.new
    @virtualtest.duration = params[:virtualtest][:duration]
    @virtualtest.online = false

    nombre = 0
    loop do
      nombre = rand(100)
      break if Virtualtest.where(:number => nombre).count == 0
    end
    @virtualtest.number = nombre

    if @virtualtest.save
      flash[:success] = "Test virtuel ajouté."
      redirect_to virtualtests_path
    else
      render 'new'
    end
  end

  # Update a virtualtest (send the form)
  def update
    @virtualtest.duration = params[:virtualtest][:duration]
    if @virtualtest.save
      flash[:success] = "Test virtuel modifié."
      redirect_to virtualtests_path
    else
      render 'edit'
    end
  end

  # Delete a virtualtest
  def destroy
    @virtualtest.problems.each do |p|
      p.update(:virtualtest_id => 0, :position => 0)
    end
    @virtualtest.destroy
    flash[:success] = "Test virtuel supprimé."
    redirect_to virtualtests_path
  end

  # Put a virtualtest online
  def put_online
    @virtualtest.update_attribute(:online, true)
    flash[:success] = "Test virtuel mis en ligne."
    redirect_to virtualtests_path
  end

  # Begin a virtualtest
  def begin_test
    t = Takentest.create(:user => current_user, :virtualtest => @virtualtest, :status => :in_progress, :taken_time => DateTime.now)    
    Takentestcheck.create(:takentest => t)    
    redirect_to @virtualtest
  end

  private
  
  ########## GET METHODS ##########

  # Get the virtualtest
  def get_virtualtest
    @virtualtest = Virtualtest.find_by_id(params[:id])
    return if check_nil_object(@virtualtest)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user is currently doing the virtualtest
  def user_in_test
    virtualtest_status = current_user.test_status(@virtualtest)
    render 'errors/access_refused' if virtualtest_status == "not_started"
    redirect_to virtualtests_path if virtualtest_status == "finished" # Smoothly redirect because it can happen when timer stops
  end

  # Check that current user has access to the virtualtest
  def user_can_see_virtualtest
    if !has_enough_points(current_user)
      render 'errors/access_refused' and return
    end
    visible = true
    @virtualtest.problems.each do |p|
      p.chapters.each do |c|
        visible = false if !current_user.chap_solved?(c)
      end
    end
    if !visible
      render 'errors/access_refused'
    end
  end

  # Check that the virtualtest is online
  def online_virtualtest
    return if check_offline_object(@virtualtest)
  end
  
  # Check that the vitualtest is offline
  def offline_virtualtest
    return if check_online_object(@virtualtest)
  end

  # Check that the virtual test can be put online
  def virtualtest_can_be_online
    nb_prob = 0
    can_online = true
    @virtualtest.problems.each do |p|
      can_online = false if !p.online?
      nb_prob = nb_prob + 1
    end
    redirect_to virtualtests_path if !can_online || nb_prob == 0
  end

  # Check that current user can start the test
  def user_can_begin_virtualtest
    if @no_new_submission
      flash[:info] = @no_new_submission_message
      redirect_to virtualtests_path
    elsif current_user.has_sanction_of_type(:no_submission)
      flash[:info] = current_user.last_sanction_of_type(:no_submission).message
      redirect_to virtualtests_path
    elsif current_user.test_status(@virtualtest) != "not_started"
      redirect_to virtualtests_path
    elsif Takentest.where(:user => current_user, :status => :in_progress).count > 0
      flash[:danger] = "Vous avez déjà un test virtuel en cours !"
      redirect_to virtualtests_path
    end
  end
end
