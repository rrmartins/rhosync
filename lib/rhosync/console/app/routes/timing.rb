require 'json'

class RhosyncConsole::Server
  get '/timing' do
    if login_required
      redirect url_path('/')
      return
    end
    @currentpage = "Statistics"
    @pagetitle = "Statistics" #H1 title
    
    @initialcontent = url_path('/timing/usercount')
    
    @locals = {
      :div => "main_box",
      :links => [ 
        { :url => url_path('/timing/usercount'), :selected => true, :title => 'User Count' },
        { :url => url_path('/timing/devicecount'), :title => 'Device Count' },
        { :url => url_path('/timing/httptiming'), :title => 'HTTP Timing' },
        { :url => url_path('/timing/bysource'), :title => 'Source Timing' }
      ]
    }
    
    erb :content
  end
  

  get '/timing/bydevice' do
    '<div id="chartdiv" style="height:400px;width:300px; "></div> '
  end
  
  def count_graph(uri,title,name,metric)
    @uri   = 'uri'
    
    start = 0
    finish = -1
    now = Time.now.to_i
    format = "%m/%d/%y %H:%M:%S"

    thisdata = []
    series = []
    series << 
    options = { :legend => { :show => false },  :title => title }
    @sources = []

    s = {}
    usercount = []

    begin
      usercount = JSON.parse RhosyncApi::stats(session[:server],session[:token], {:metric => metric, :start => start, :finish => finish})
    rescue Exception => e
      usercount = ["0:#{Time.now.to_i}"]
    end
    usercount.each do |count|
      user,timestamp = count.split(':')
      user = user.to_i
      timestamp = timestamp.to_i * 1000
      thisdata << [timestamp,user]
    end
    
      options[:axes] = {
         :xaxis => { :autoscale => true, :renderer=>'$.jqplot.DateAxisRenderer',
           :tickOptions => {:formatString => format}},
         :yaxis => {:label  => name, :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'}
       }
      
    options[:cursor] = {:zoom => true, :showTooltip => true} 
    s['name'] = name
    s['data'] = [thisdata]
    s['options'] = options
    @sources << s
    erb :jqplot, :layout => false
  end
  
  get '/timing/usercount' do
    count_graph('timing/usercount', "User Count", "Users", "users")
  end

  get '/timing/devicecount' do
    count_graph('timing/devicecount', "Device Count", "Devices", "clients")
  end
  
  
  
  get '/timing/bysource' do
    @uri   = 'timing/bysource'
    
    #name,data,options
    @displayname = params['display']
    names = []
    handle_api_error("Can't load list of sources") do
      names = RhosyncApi::list_sources(session[:server],session[:token],:all)
    end
    @sources = []
    
    names.each do |name|
      s = {}
      data = []
      series = []
      options = { :legend => { :show => true }, :title => name }
      s['name'] = name
      
      keys = JSON.parse RhosyncApi::stats(session[:server],session[:token], :names => "source:*:#{name}")
      
      xmin = 9999999999999999
      xmax = -1
      ymin = 9999999999999999
      ymax = -1
      keys.each do |key|
        method = key.gsub(/source:/,"").gsub(/:.*/,"")
        series << {:showLabel => true, :label => method }
        #range = r.zrange(key,0,-1)
        range = JSON.parse RhosyncApi::stats(session[:server],session[:token], {:metric => key, :start => 0, :finish => -1})
        thisdata = []
        range.each do |value|
          count = value.split(',')[0]
          value.gsub!(/.*,/,"")
          thisdata << value.split(":").reverse
          thisdata[-1][0] = thisdata[-1][0].to_i * 1000
          thisdata[-1][1] = thisdata[-1][1].to_f
          thisdata[-1][1] /= count.to_f
          
          ymin = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f < ymin
          ymax = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f > ymax
          
        end
        data << thisdata
        xmin = thisdata[0][0].to_i if thisdata[0] && thisdata[0][0].to_i < xmin
        xmax = thisdata[-1][0].to_i if thisdata[-1]  && thisdata[-1][0].to_i > xmax
      end
      #ticks = []
      #xmin..xmax.step(60) {|x| ticks << x }

      options[:axes] = {
        :yaxis => { :tickOptions => { :formatString =>'%.3f'}, :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05), :label  => 'Seconds', :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'  }, 
        :xaxis => { :autoscale => true, :renderer=>'$.jqplot.DateAxisRenderer',
          :tickOptions => {:formatString => '%m/%d/%y %H:%M:%S'}}
      }


      # options[:axes] = {
      #   :yaxis => { :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05) }, 
      #   :xaxis => { :autoscale => true, :min => xmin - 60, :max => xmax + 60,  :renderer=>'$.jqplot.DateAxisRenderer',
      #     :tickOptions => {:formatString => '%m/%d/%y %H:%M:%S'}}
      # }

      s['data'] = data
      options[:series] = series
      options[:cursor] = {:zoom => true, :showTooltip => true} 
      
#      options[:seriesDefaults] = { :showMarker => false}
#      options[:seriesDefaults] = { :renderer => '$.jqplot.BarRenderer', :rendererOptions => {:barPadding => 8, :barMargin => 20}}
      s['options'] = options
      
      @sources << s
    end
    
    @data = [[[1,2],[3,4],[5,6]]].to_json
    erb :jqplot, :layout => false
  end


 get '/timing/httptiming' do
    @uri   = 'timing/httptiming'
    
    #name,data,options
    @displayname = params['display']
    names = ["GET","POST"]
    handle_api_error("Can't load list of sources") do
      names = RhosyncApi::list_sources(session[:server],session[:token],:all)
    end
    names << "ALL"
    @sources = []
    
    names.each do |name|
      s = {}
      data = []
      series = []
      options = { :legend => { :show => true }, :title => name }
      s['name'] = name
      
      name = "*" if name == "ALL"
      keys = JSON.parse RhosyncApi::stats(session[:server],session[:token], :names => "http:*:#{name}")
      
      xmin = 9999999999999999
      xmax = -1
      ymin = 9999999999999999
      ymax = -1
      keys.each do |key|
        method = key.gsub(/http:.*?:/,"")
        method.gsub!(/:.*/,"") unless name == "*"
        series << {:showLabel => true, :label => method }
        #range = r.zrange(key,0,-1)
        range = JSON.parse RhosyncApi::stats(session[:server],session[:token], {:metric => key, :start => 0, :finish => -1})
        thisdata = []
        range.each do |value|
          count = value.split(',')[0]
          value.gsub!(/.*,/,"")
          thisdata << value.split(":").reverse
          thisdata[-1][0] = thisdata[-1][0].to_i * 1000
          thisdata[-1][1] = thisdata[-1][1].to_f
          thisdata[-1][1] /= count.to_f
          
          ymin = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f < ymin
          ymax = thisdata[-1][1].to_f if thisdata[-1][1] && thisdata[-1][1].to_f > ymax
          
        end
        data << thisdata
        xmin = thisdata[0][0].to_i if thisdata[0] && thisdata[0][0].to_i < xmin
        xmax = thisdata[-1][0].to_i if thisdata[-1]  && thisdata[-1][0].to_i > xmax
      end
      #ticks = []
      #xmin..xmax.step(60) {|x| ticks << x }

      options[:axes] = {
        :yaxis => { :tickOptions => { :formatString =>'%.3f'}, :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05), :label  => 'Seconds', :labelRenderer => '$.jqplot.CanvasAxisLabelRenderer'  }, 
        :xaxis => { :autoscale => true, :renderer=>'$.jqplot.DateAxisRenderer',
          :tickOptions => {:formatString => '%m/%d/%y %H:%M:%S'}}
      }


      # options[:axes] = {
      #   :yaxis => { :autoscale => true, :min => 0, :max => ymax + (ymax * 0.05) }, 
      #   :xaxis => { :autoscale => true, :min => xmin - 60, :max => xmax + 60,  :renderer=>'$.jqplot.DateAxisRenderer',
      #     :tickOptions => {:formatString => '%m/%d/%y %H:%M:%S'}}
      # }

      s['data'] = data
      options[:series] = series
      options[:cursor] = {:zoom => true, :showTooltip => true} 
      
#      options[:seriesDefaults] = { :showMarker => false}
#      options[:seriesDefaults] = { :renderer => '$.jqplot.BarRenderer', :rendererOptions => {:barPadding => 8, :barMargin => 20}}
      s['options'] = options
      
      @sources << s
    end
    
    @data = [[[1,2],[3,4],[5,6]]].to_json
    erb :jqplot, :layout => false
  end
end