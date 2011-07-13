module Constants

PACKAGES                = ["rubygems",
                           "build-essential",
                           "zlib1g-dev",
                           "libcurl4-openssl-dev",
                           "apache2-mpm-prefork",
                           "apache2-prefork-dev",
                           "libapr1-dev",
                           "libaprutil1-dev"]

RUBYGEMS                = "rubygems-1.8.5"

SOFTWARE                = [RUBYGEMS]

RUBYGEMS_URL            = "http://rubyforge.org/frs/download.php/74954/" + 
                          "#{ RUBYGEMS }.tgz"

URLS                    = [RUBYGEMS_URL]

GEMS                    = ["rhosync",
                           "passenger"]

SUPPORTED_PKG_MGRS      = ["apt-get", "yum"]

SUPPORTED_WEB_SERVERS   = ["apache2", "nginx"]

WEB_SERVER_URL          = "http://localhost/"

CHECKS                  = ["check_all_packages",
                           "check_all_gems",
                           "check_web_server_running"]

DEFAULT_INSTALL_DIR     = "/opt/rhoconnect/"

DEFAULTS                = {"Packages" => PACKAGES,
                           "Software" => SOFTWARE,
                           "Gems" => GEMS,
                           "Supported Package Managers" => SUPPORTED_PKG_MGRS,
                           "Supported Web Servers" => SUPPORTED_WEB_SERVERS,
                           "Default Install Directory" => DEFAULT_INSTALL_DIR}
end #Constants
