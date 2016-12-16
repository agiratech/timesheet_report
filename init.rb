Redmine::Plugin.register :timesheet_report do
  name 'Time sheet report'
  author 'Agiratech'
  description 'Plugin to draw charts for time sheet reports'
  version '0.0.1'
  url 'http://www.agiratech.com/'
  author_url 'http://www.agiratech.com'

  permission :charts, { :charts => [:index, :vote] }, :public => true
  menu :project_menu, :charts,
    { :controller => 'charts', :action => 'index' },
    :caption => :charts,
    :last => :true,
    :param => :id
end
