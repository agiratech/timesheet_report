class ChartsController < ApplicationController

  unloadable
  before_filter :find_project

  def index
    date = Date.today
    @from = params[:from_date].present? ? params[:from_date].to_date : date.beginning_of_month
    @to = params[:to_date].present? ? params[:to_date].to_date : date.end_of_month
    @current_user = find_current_user
    @user = User.where("type =? && admin =?", "User",0).order("login ASC")

    @query = TimeEntryQuery.build_from_params(params, :project => @project, :name => '_')
    scope = time_entry_scope.where(:spent_on => @from..@to)
    scope = scope.where("user_id =?", params[:user_id]) if params[:user_id].present?
    report = Redmine::Helpers::TimeReport.new(@project, @issue, ["cf_22"], "month", scope)

    # ***** Time spent vs Projects *****
    overall_time_spent = Hash.new
    @overall_time_spent_result = Array.new
    report.hours.each do |hour|
      overall_time_spent[hour["cf_22"]] = overall_time_spent[hour["cf_22"]].to_f + hour["hours"].to_f
    end
    overall_time_spent.each do |key, value|
      @overall_time_spent_result << [key, value.round(1)]
    end
    # ***** Time spent vs Projects *****
    daily_time_spent = Hash.new
    @daily_time_spent_result = Array.new

    report.hours.each do |hour|
      daily_time_spent[hour["cf_22"]] = Hash.new if daily_time_spent[hour["cf_22"]].nil?
      daily_time_spent[hour["cf_22"]][hour["spent_on"].to_s] = hour["hours"].to_f + daily_time_spent[hour["cf_22"]][hour["hours"]].to_f
    end
    dates = (@from..@to)
    @date_range = dates.map{ |date| date.strftime("%D") }
    @date_wise_spent = []
    daily_time_spent.each do |project_name, time_spent|
      daily_spent = []
      dates.each do |date|
        daily_spent << time_spent[date.to_s].to_f.round(1)
      end
      @date_wise_spent << {
        name: project_name,
        data: daily_spent
      }
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
