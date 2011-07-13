require './rho_connect_install_constants'

module DownloadAndDocompress
  extend self
  
  # download_and_decompress
  # Delegates the download and decompression duties
  def download_and_decompress(prefix)
    print_header "Downloading and Decompressing"
    downloads = 0
    Constants::URLS.each do |url|
      if !File.exists?("#{ get_tarball_name url }") ||
         !File.exists?("#{ get_version url }")
        wget_download prefix, url
        decompress prefix, url
        downloads += 1
      end #if
    end #do
    if downloads == 0
      log_print "Nothing additional to download"
    end #if
  end #download_and_decompress

  # wget_download
  # Takes a URL and the name of a tarball and issues a wget command on said 
  # URL  unless the tarball or directory already exists
  def wget_download(prefix, url)
    if !File.exists?("#{ prefix }#{ get_tarball_name url }") &&
       !File.directory?("#{ prefix }#{ get_version url }")
        cmd "wget -P #{ prefix } #{ url }"
    end #if
  end #wget_download

  # decompress
  # Decompress downloaded files unless already decompressed directory
  # exists
  def decompress(prefix, url)
    tarball = get_tarball_name(url)
    dir = get_version(url)
    cmd "tar -xzf #{ prefix }#{ tarball } -C #{ prefix }"  unless
      File.directory? "#{ prefix }#{ dir }"
  end #decompress
  
  # get_version
  # This method extracts the untarballed name of files retrieved via wget
  # from their URL
  def get_version(url)
    url =~ /.*\/(.*)\.t.*\Z/
    $1
  end #get_version

  # get_tarball_name
  # This method extracts the name of files retrieved via wget from their URL
  def get_tarball_name(url)
    url =~ /.*\/(.*\.t.*)/
    $1
  end #get_tarball_name
  
end #DownloadAndDocompress
