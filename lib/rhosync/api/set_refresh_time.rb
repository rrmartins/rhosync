Rhosync::Server.api :set_refresh_time do |params,user|
  source = Source.load(params[:source_name],
    {:app_id => params[:app_name], :user_id => params[:user_name]})
  params[:poll_interval] ||= 0
  source.read_state.refresh_time = Time.now.to_i + params[:poll_interval].to_i
  ''
end