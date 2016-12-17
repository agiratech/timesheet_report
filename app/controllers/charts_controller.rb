class ChartsController < ApplicationController

  unloadable
  before_filter :find_project, :initialize_defaults

  def index
    if @reports.present?
      project_specific_chart
      user_specific_chart
    end
  end

  private

  def project_specific_chart
    @chart1_title = 'Time Spent vs Projects'
    @chart2_title = 'Daily Time Spent vs Projects'
    # ************************** Time Spent vs Users **************************
    users_hash = {}
    @users.map {|user| users_hash[user.id] = user.firstname.capitalize + " " + user.lastname }
    overall_time_spent = Hash.new
    if params[:custom_project_name].present?
      @reports.hours.each do |hour|
        overall_time_spent[hour["user"]] = overall_time_spent[hour["user"]].to_f + hour["hours"].to_f if params[:custom_project_name] == hour[@custom_filter_type]
      end
    else
      @reports.hours.each do |hour|
        overall_time_spent[hour["user"]] = overall_time_spent[hour["user"]].to_f + hour["hours"].to_f
      end
    end
    overall_time_spent.each do |key, value|
      @overall_project_time_spent_result << [users_hash[key], value.round(1)]
    end
    # ************************** Daily Time Spent vs Users **************************
    daily_time_spent_vs_users(users_hash)
  end

  def daily_time_spent_vs_users(users_hash)
    daily_time_spent = Hash.new
    dates = (@from..@to)
    @date_range = dates.map{ |date| date.strftime("%D") }
    if params[:custom_project_name].present?
      @reports.hours.each do |hour|
        if params[:custom_project_name] == hour[@custom_filter_type]
          daily_time_spent[hour["user"]] = Hash.new if daily_time_spent[hour["user"]].nil?
          daily_time_spent[hour["user"]][hour["spent_on"].to_s] = hour["hours"].to_f + daily_time_spent[hour["user"]][hour["spent_on"].to_s].to_f
        end
      end
    else
      @reports.hours.each do |hour|
        daily_time_spent[hour["user"]] = Hash.new if daily_time_spent[hour["user"]].nil?
        daily_time_spent[hour["user"]][hour["spent_on"].to_s] = hour["hours"].to_f + daily_time_spent[hour["user"]][hour["spent_on"].to_s].to_f
      end
    end
    daily_time_spent.each do |user_id, time_spent|
      daily_spent = []
      dates.each do |date|
        daily_spent << time_spent[date.to_s].to_f.round(1)
      end
      @date_wise_project_spent << {
        name: users_hash[user_id],
        data: daily_spent
      }
    end
  end

  def user_specific_chart
    @chart3_title = 'Time Spent vs Users'
    @chart4_title = 'Daily Time Spent vs Users'
    # ************************** Time spent vs Projects **************************
    overall_time_spent = Hash.new
    @reports.hours.each do |hour|
      overall_time_spent[hour[@custom_filter_type]] = overall_time_spent[hour[@custom_filter_type]].to_f + hour["hours"].to_f
    end
    if params[:custom_project_name].present?
      @overall_user_time_spent_result << [params[:custom_project_name], overall_time_spent[params[:custom_project_name]].to_f.round(1)] if overall_time_spent[params[:custom_project_name]]
    else
      overall_time_spent.each do |key, value|
        @overall_user_time_spent_result << [key, value.round(1)]
      end
    end
    # ***** Daily Time spent vs Projects *****
    daily_time_spent = Hash.new
    @reports.hours.each do |hour|
      daily_time_spent[hour[@custom_filter_type]] = Hash.new if daily_time_spent[hour[@custom_filter_type]].nil?
      daily_time_spent[hour[@custom_filter_type]][hour["spent_on"].to_s] = hour["hours"].to_f + daily_time_spent[hour[@custom_filter_type]][hour["hours"]].to_f
    end
    dates = (@from..@to)
    @date_range = dates.map{ |date| date.strftime("%D") }
    daily_time_spent.each do |project_name, time_spent|
      daily_spent = []
      dates.each do |date|
        daily_spent << time_spent[date.to_s].to_f.round(1)
      end
      if params[:custom_project_name].present? && project_name == params[:custom_project_name]
        @date_wise_user_spent << {
          name: project_name,
          data: daily_spent
        }
      elsif !params[:custom_project_name].present?
        @date_wise_user_spent << {
          name: project_name,
          data: daily_spent
        }
      end
    end
  end

  # Returns the TimeEntry scope for index and report actions
  def time_entry_scope(options={})
    scope = @query.results_scope(options)
    if @issue
      scope = scope.on_issue(@issue)
    end
    scope
  end

  def initialize_defaults
    @custom_project_field = CustomField.where("type =? AND name =?", "TimeEntryCustomField", "Project Name").first
    if @custom_project_field.present?
      @date_wise_user_spent = []
      @overall_user_time_spent_result = Array.new
      @date_wise_project_spent = []
      @overall_project_time_spent_result = Array.new
      @custom_filter_type = "cf_#{@custom_project_field.id}"
      @date = Date.today
      @from = params[:from_date].present? ? params[:from_date].to_date : @date.beginning_of_month
      @to = params[:to_date].present? ? params[:to_date].to_date : @date.end_of_month
      @current_user = find_current_user
      user_id = @current_user.admin ? params[:user_id] :  @current_user.id
      @users = User.where("type =?", "User").order("login ASC")
      @query = TimeEntryQuery.build_from_params(params, :project => @project, :name => '_')
      scope = time_entry_scope.where(:spent_on => @from..@to)
      scope = scope.where("user_id =?", user_id) if user_id.present?
      @reports = Redmine::Helpers::TimeReport.new(@project, @issue, ["user", @custom_filter_type], "day", scope)
    end
  end
end
