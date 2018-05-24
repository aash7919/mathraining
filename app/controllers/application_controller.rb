#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper

  before_action :has_consent
  before_action :check_up
  #before_action :warning

  ########## PARTIE PRIVEE ##########
  private

  def warning
    #flash[:info] = "Attention! Ce <b>vendredi 14 avril 2017</b>, une mise à jour du site aura lieu et celui-ci sera inaccessible pendant une bonne partie de la journée. Merci pour votre compréhension.".html_safe
  end
  
  def has_consent
    $allcolors = Color.order(:pt).to_a
    @ss = signed_in?
    pp = request.fullpath.to_s
    if @ss && current_user.consent.nil? && current_user.admin && pp != "/accept_legal" && pp != "/legal" && pp != "/about" && pp != "/contact" && pp != "/signout"
      render 'users/read_legal'
    end
  end

  # Regarde s'il y a un test virtuel qui vient de se terminer
  def check_up
    maintenant = DateTime.now.to_i
    Takentest.where(status: 0).each do |t|
      debut = t.takentime.to_i
      if debut + t.virtualtest.duration*60 < maintenant
        t.status = 1
        t.save
        u = t.user
        v = t.virtualtest
        v.problems.each do |p|
          p.submissions.where(user_id: u.id, intest: true).each do |s|
            s.visible = true
            s.save
          end
        end
      end
    end
  end

  # Vérifie qu'il ne s'agit pas d'un administrateur dans la peau de quelqu'un
  def notskin_user
    if current_user.other
      flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
      redirect_to(:back)
    end
  end

  # Vérifie qu'on est administrateur
  def admin_user
    if(!current_user.sk.admin)
      flash[:danger] = "Vous n'avez pas accès à cette page."
      redirect_to root_path
    end
  end

  # Vérifie qu'on est root
  def root_user
    if(!current_user.sk.root)
      flash[:danger] = "Vous n'avez pas accès à cette page."
      redirect_to root_path
    end
  end

  # Gérer les pièces jointes
  def create_files
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Myfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          destroy_files(attach, i)
          nom = params["file#{k}".to_sym].original_filename
          @error = true
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return [];
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      destroy_files(attach, i)
      @error = true
      @error_message = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)."
      return [];
    end

    return attach
  end

  def update_files(about, type)
    totalsize = 0
    about.myfiles.each do |f|
      if params["prevfile#{f.id}".to_sym].nil?
        f.file.destroy
        f.destroy
      else
        totalsize = totalsize + f.file_file_size
      end
    end

    about.fakefiles.each do |f|
      if params["prevfakefile#{f.id}".to_sym].nil?
        f.destroy
      end
    end

    attach = Array.new

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Myfile.new(:file => params["file#{k}".to_sym])
        attach[i-1].myfiletable = about
        if !attach[i-1].save
          destroy_files(attach, i)
          nom = params["file#{k}".to_sym].original_filename
          @error = true
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return []
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      destroy_files(attach, i)
      @error = true
      @error_message = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)"
      return []
    end
  end

  def destroy_files(attach, i)
    j = 1
    while j < i do
      attach[j-1].file.destroy
      attach[j-1].destroy
      j = j+1
    end
  end
end
