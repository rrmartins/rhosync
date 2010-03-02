Rhosync::Server.api :set_refresh_time do |params,user|
  source = Source.load(params[:source_name],
    {:app_id => params[:app_name], :user_id => params[:user_name]})
  source.poll_interval = params[:poll_interval] if params[:poll_interval]
  params[:refresh_time] ||= 0
  source.read_state.refresh_time = Time.now.to_i + params[:refresh_time].to_i
  ''
end