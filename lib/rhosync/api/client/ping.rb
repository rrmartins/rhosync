Server.api :ping, :client do |params,user|
  if params['async']
    PingJob.enqueue(params)
  else
    PingJob.perform(params)
  end
end