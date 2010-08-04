Server.api :ping do |params,user|
  if params['async']
    PingJob.enqueue(params)
  else
    PingJob.perform(params)
  end
end