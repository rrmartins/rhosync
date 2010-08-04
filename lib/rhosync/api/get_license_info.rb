Server.api :get_license_info do |params,user|
  {:rhosync_version => Rhosync.license.rhosync_version, 
   :licensee => Rhosync.license.licensee, 
   :seats => Rhosync.license.seats, 
   :issued => Rhosync.license.issued,
   :available => Rhosync.license.available }.to_json
end
