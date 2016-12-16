class ChartsController < ApplicationController

  unloadable
  before_filter :find_project

  def index
    @custom_project_field = CustomField.where("type =? AND name =?", "TimeEntryCustomField", "Project Name").first
    if @custom_project_field.present?
      date = Date.today
      @from = params[:from_date].present? ? params[:from_date].to_date : date.beginning_of_month
      @to = params[:to_date].present? ? params[:to_date].to_date : date.end_of_month
      @current_user = find_current_user
      @users = User.where("type =? && admin =?", "User",0).order("login ASC")
      # @projects = User.where("type =? && admin =?", "User",0).order("login ASC")

      @query = TimeEntryQuery.build_from_params(params, :project => @project, :name => '_')
      scope = time_entry_scope.where(:spent_on => @from..@to)
      scope = scope.where("user_id =?", params[:user_id]) if params[:user_id].present?
      # scope = scope.where("user_id =?", params[:project_id]) if params[:project_id].present?
      report = Redmine::Helpers::TimeReport.new(@project, @issue, ["cf_#{@custom_project_field.id}"], "month", scope)

      # ***** Time spent vs Projects *****
      overall_time_spent = Hash.new
      @overall_time_spent_result = Array.new
      report.hours.each do |hour|
        overall_time_spent[hour["cf_#{@custom_project_field.id}"]] = overall_time_spent[hour["cf_#{@custom_project_field.id}"]].to_f + hour["hours"].to_f
      end
      if params[:custom_project_name].present?
        @overall_time_spent_result << [params[:custom_project_name], overall_time_spent[params[:custom_project_name]].to_f.round(1)] if overall_time_spent[params[:custom_project_name]]
      else
        overall_time_spent.each do |key, value|
          @overall_time_spent_result << [key, value.round(1)]
        end
      end
      # ***** Time spent vs Projects *****
      daily_time_spent = Hash.new
      @daily_time_spent_result = Array.new

      report.hours.each do |hour|
        daily_time_spent[hour["cf_#{@custom_project_field.id}"]] = Hash.new if daily_time_spent[hour["cf_#{@custom_project_field.id}"]].nil?
        daily_time_spent[hour["cf_#{@custom_project_field.id}"]][hour["spent_on"].to_s] = hour["hours"].to_f + daily_time_spent[hour["cf_#{@custom_project_field.id}"]][hour["hours"]].to_f
      end
      dates = (@from..@to)
      @date_range = dates.map{ |date| date.strftime("%D") }
      @date_wise_spent = []
      daily_time_spent.each do |project_name, time_spent|
        daily_spent = []
        dates.each do |date|
          daily_spent << time_spent[date.to_s].to_f.round(1)
        end
        if params[:custom_project_name].present? && project_name == params[:custom_project_name]
          @date_wise_spent << {
            name: project_name,
            data: daily_spent
          }
        elsif !params[:custom_project_name].present?
          @date_wise_spent << {
            name: project_name,
            data: daily_spent
          }
        end
      end
    end
  end

  private

  # Returns the TimeEntry scope for index and report actions
  def time_entry_scope(options={})
    scope = @query.results_scope(options)
    if @issue
      scope = scope.on_issue(@issue)
    end
    scope
  end
end
