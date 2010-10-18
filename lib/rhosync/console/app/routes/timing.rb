require 'json'

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
    '<div id="chartdiv" style="height:400px;width:300px; "></div> '
  end
  
  get '/timing/bysource' do
    r = Redis.new
    #name,data,options
    names = []
    handle_api_error("Can't load list of sources") do
      names = RhosyncApi::list_sources(session[:server],session[:token],:all)
    end
    @sources = []
    
    names.each do |name|
      s = {}
      data = []
      series = []
      options = { :legend => { :show => true } }
      s['name'] = name
      
      keys = r.keys "stat:source:*:#{name}"
      
      xmin = 999999999999
      xmax = -1
      ymin = 999999999999
      ymax = -1
      keys.each do |key|
        method = key.gsub(/stat:source:/,"").gsub(/:.*/,"")
        series << {:showLabel => true, :label => method }
        range = r.zrange(key,0,-1)
        thisdata = []
        range.each do |value|
          value.gsub!(/.*,/,"")
          thisdata << value.split(":").reverse
          
          ymin = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f < ymin
          ymax = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f > ymax
          
        end
        data << thisdata
        xmin = thisdata[0][0].to_i if thisdata[0] && thisdata[0][0].to_i < xmin
        xmax = thisdata[-1][0].to_i if thisdata[-1]  && thisdata[-1][0].to_i > xmax
      end
      ticks = []
      xmin..xmax.step(60) {|x| ticks << x }

      options[:axes] = {
        :yaxis => { :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05) }, 
        :xaxis => { :autoscale => true, :min => xmin - 60, :max => xmax + 60, :ticks => ticks }
      }
      s['data'] = data
      options[:series] = series
      s['options'] = options
      
      @sources << s
    end
    
    @data = [[[1,2],[3,4],[5,6]]].to_json
    erb :timingbysource, :layout => :false
  end
end