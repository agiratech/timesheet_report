Redmine::Plugin.register :timesheet_report do
  name 'Team Work Chart'
  author 'Agira'
  description 'Plugin to draw charts for time spents for projects'
  version '0.0.1'
  url 'http://agiratech.com'
  author_url 'http://agiratech.com'

  permission :charts, { :charts => [:index, :vote] }, :public => true
  menu :project_menu, :charts,
    { :controller => 'charts', :action => 'index' },
    :caption => :charts,
    :last => :true,
    :param => :id

end