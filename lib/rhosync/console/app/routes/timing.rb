class RhosyncConsole::Server
  get '/timing' do
    @currentpage = "Timing"
    @pagetitle = "Timing" #H1 title
    
    @initialcontent = url('/timing/bydevice')
    
    @locals = {
      :div => "main_box",
      :links => [ 
        { :url => url('/timing/bydevice'), :selected => true, :title => 'By Device' },
        { :url => url('/timing/bysource'), :title => 'By Source' }
      ]
    }
    
    erb :content
  end
  
  get '/timing/bydevice' do
    "testing device"
  end
  
  get '/timing/bysource' do
    "testing source<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>"
  end
end