Server.api :stats do |params,user|
  if Rhosync.stats == true
    names = params[:names]
    if names
      Rhosync::Stats::Record.keys(names).to_json
    else
      metric = params[:metric]
      rtype = Rhosync::Stats::Record.rtype(metric)
      if rtype == 'zset'
        # returns [] if no results
        Rhosync::Stats::Record.range(metric,params[:start],params[:finish]).to_json 
      elsif rtype == 'string'
        Rhosync::Stats::Record.get_value(metric) || ''
      else
        raise ApiException.new(404, "Unknown metric")
      end
    end
  else
    raise ApiException.new(500, "Stats not enabled")
  end
end