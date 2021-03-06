class TeamsController < ApplicationController
  before_action :signed_in_user
  before_action :signed_in_instructor, except: [:index, :show, :work_track]
  before_action :team_access, only: [:work_track, :team_track]
  
  def new
    @team = Team.new

    # Set active projects defined in application controller
    set_active_projects
  end

  def create
    @url = "create"
    @team = Team.new(team_params)
    if team_params[:project_id]
      @team.project = Project.find(team_params[:project_id])
      if @team.save
        flash[:success] = "New team was successfully created. "
        redirect_to teams_path
      else
        flash[:error] = @team.errors.full_messages.join(", ").html_safe
        render 'new'
      end
    else
      flash[:error] = 'Please select project to make a team'
      redirect_to :back
    end
  end

  def show
    set_team
  end

  def edit
    set_team
    set_active_projects
    @url = "update"
  end

  def index
    if current_user.utype == "instructor"
      @teams = []
      @instructor_terms = InstructorTerm.where(:instructor_id => current_user.instructor.id)
      @instructor_terms.each do |it|
        Team.all.each do |t|
          if t.project.semester == it.semester && t.project.active
            @teams << t
          end
        end
      end
    elsif current_user.sponsor
      @projects = Project.where(:sponsor_id => current_user.sponsor.id)
      @teams = Team.where(:project_id => @projects.ids)
    elsif current_user.student
      redirect_to root_path
      flash[:warning] = "You don't have the permission"
    else
      @teams=[]
      Team.all.each do |t|
        if t.project.active
          @teams << t
        end
      end
    end
  end

  def past
    if current_user.utype == "instructor"
      @teams = []
      @instructor_terms = InstructorTerm.where(:instructor_id => current_user.instructor.id)
      @instructor_terms.each do |it|
        Team.all.each do |t|
          if t.project.semester == it.semester && !t.project.active
            @teams << t
          end
        end
      end
    elsif current_user.sponsor
      @projects = Project.where(:sponsor_id => current_user.sponsor.id)
      @teams = Team.where(:project_id => @projects.ids)
    elsif current_user.student
      redirect_to root_path
      flash[:warning] = "You don't have the permission"
    else
      @teams=[]
      Team.all.each do |t|
        if !t.project.active
          @teams << t
        end
      end
    end
  end

  def update
    set_team
    @url = "update"
    if @team.update_attributes(team_params)
      flash[:success] = "Team was successfully updated. "
      redirect_to team_path(@team.id)
    else
      flash[:error] = @team.errors.full_messages.join(", ").html_safe
      render 'edit'
    end
  end

  def add_students
    if params[:team] == ""
      flash[:error] = 'No team was selected.'
      #redirect_to assignment_teams_path
    elsif params[:student].nil?
           flash[:error] = "No student was selected."
           #redirect_to assignment_teams_path
    else
        team = Team.find_by_id(params[:team])
        Student.where(:id => params[:student]).update_all(:status => true)

        team.students << Student.find(params[:student])
        team.save
        flash[:success] = "Student has been successfully assigned."
    end
    redirect_to :back
  end

  def unassign_students
    if params[:student].nil?
      flash[:error] = "No student was selected."
    else
      Student.where(:id => params[:student]).update_all(:status => false)
      Student.where(:id => params[:student]).update_all(:team_id => nil)
      flash[:success] = "Student has been successfully unassigned."
    end
    redirect_to :back
  end

  def team_assignment
    @students = Student.all
    @teams=[]
    Team.all.each do |t|
      if t.project.active
        @teams << t
      end
    end
  end

  #TODO OPRAM SYSTEM CALL FUNCTION
  def opram_system
    temp = current_user.name + " " + Time.now.to_s
    key = ActiveSupport::KeyGenerator.new('token').generate_key("UNL-cse-ilab")
    crypt = ActiveSupport::MessageEncryptor.new(key)
    encrypted_data = crypt.encrypt_and_sign(temp)
    AuthToken.create(:token => encrypted_data)
    url = opram_url + "?token=#{encrypted_data}"
    redirect_to url
  end

  def team_work
    if current_user.utype == "instructor"
      @teams = []
      @instructor_terms = InstructorTerm.where(:instructor_id => current_user.instructor.id)
      @instructor_terms.each do |it|
        Team.all.each do |t|
          if t.project.semester == it.semester && t.project.active
            @teams << t
          end
        end
      end
    elsif current_user.sponsor
      @projects = Project.where(:sponsor_id => current_user.sponsor.id)
      @teams = Team.where(:project_id => @projects.ids)
    elsif current_user.student
      redirect_to root_path
      flash[:warning] = "You don't have the permission"
    else
      @teams=[]
      Team.all.each do |t|
        if t.project.active
          @teams << t
        end
      end
    end
  end

  def team_track
    @team = Team.find(params[:id])
    @tasks = Event.where("team_id = #{params[:id]}")
    render partial: "work_track", locals: { tasks: @tasks, team: @team}
  end

  def work_track
    @tasks = Event.where("team_id = #{params[:id]}")
  end

  def delete_teams
    Team.destroy(params[:team])
    redirect_to teams_path
  end

  private

    def team_params
      params.require(:team).permit(:name, :project_id, :google_drive, :trello_link)
    end

    def set_team
      @team = Team.find_by_id(params[:id])
    end

end
