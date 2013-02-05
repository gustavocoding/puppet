require 'puppet/resource'
require 'puppet/resource/catalog'
require 'puppet/indirector'
require 'puppet/file_serving'
require 'puppet/util'
require "puppet/type/file"
require 'puppet/file_serving/base'
#require 'puppet/file_serving/indirection_hooks'
require 'puppet/file_serving/content'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'
require 'rexml/document'

Puppet::Type.type(:maven).provide(:mvn) do

  	desc "Download maven artifacts from a Maven repo, which can be hosted in artifactory, subversion or inside a puppet module"
  	include Puppet::Util::Execution

        # Finds out if url starts with puppet:// protocol
  	def is_puppet_url(url)
    		url =~ /^puppet:\/\//
  	end
 
	# Parse maven metadata file, and extract the most recent snapshot from it 
  	def extract_artifact_from_metadata(xml)
    		debug "Parsing Metadata: #{xml}"
    		xmldoc = REXML::Document.new(xml)
    		value = REXML::XPath.first(xmldoc,"//snapshotVersion[contains(./extension/text(),'jar')]/value/text()")
  	end

	# Given a maven3 metadata file, extract the most recent snapshot from it.
  	def retrieve_metadata(repos,group,artifact,version,user,pass)
		loc = repos + group.gsub(".","/") + "/" + artifact + "/" + version + "/maven-metadata.xml"
                debug "Retrieving metadata from #{loc}"
                if is_puppet_url(loc)
                	content = Puppet::FileServing::Content.indirection.find(loc)
   			file = Puppet::FileBucket::File.new(content.content)
                        file.to_s
		else
                	uri = URI.parse(loc)
                	http = Net::HTTP.new(uri.host,uri.port)
                	req = Net::HTTP::Get.new(uri.request_uri)
                	http.use_ssl = true if uri.scheme == "https"
                	if !user.nil?
                        	req.basic_auth user,pass
                	end
                	response = http.request(req)
                	body = response.body

		end
	end
	
	# Check if artifact is directly reachable by compounding the url with its coordinates
	def is_reachable(url, user, pass)
		if !is_puppet_url(url)
			debug "Calling #{url} using HEAD"
                	uri = URI.parse(url)
                	http = Net::HTTP.new(uri.host, uri.port)
                	head = Net::HTTP::Head.new(uri.request_uri)
                	http.use_ssl = true if uri.scheme == "https"
                       	head.basic_auth user, pass unless user.nil?
                	r = http.request(head)
			return true if r.code.to_i == 200
                	# If permission is denied, try to locate without user/pass
                	if r.code.to_i == 401
                        	debug "Permission denied"
                        	head = Net::HTTP::Head.new(uri.request_uri)
                        	r2 = http.request(head)
                        	return true if r2.code.to_i == 200
                	end
			
			return false
		else
 			return !Puppet::FileServing::Content.indirection.find(url).nil?
		end
	end

	
	def download_file(artifactURL, user, pass, folder, saveAs) 
		if is_puppet_url(artifactURL)
		    download_file_puppet(artifactURL, user, pass, folder, saveAs)
		else
		    download_file_http(artifactURL, user, pass, folder, saveAs)
		end
	end


	def download_file_puppet(artifactURL, user, pass, folder, saveAs) 
	
                content = Puppet::FileServing::Content.indirection.find(artifactURL)
		location = folder + "/" +  saveAs
                file =  content.content
		size = IO.binwrite(folder + saveAs, file)
		debug "Wrote #{size} bytes to #{location} from #{artifactURL}"

	end


	def download_file_http(artifactURL, user, pass, folder, saveAs) 
                command = ["/usr/bin/wget --no-check-certificate --user=#{user} --password=#{pass} -N -P #{folder} #{artifactURL} -O #{folder}/#{saveAs}"]

                timeout = @resource[:timeout].nil? ? 0 : @resource[:timeout].to_i
                output = nil
                status = nil

                begin
                        Timeout::timeout(timeout) do
                                output, status = Puppet::Util::SUIDManager.run_and_capture(command, "root", "root")
                                debug output if status.exitstatus == 0
                                debug "Exit status = #{status.exitstatus}"
                end
                rescue Timeout::Error
                        self.fail("Command timed out, increase timeout parameter if needed: #{command}")
                end

                if (status.exitstatus == 1) && (output == '')
                        self.fail("mvn returned #{status.exitstatus}: Is Maven installed?")
                end
                unless status.exitstatus == 0
                        self.fail("#{command} returned #{status.exitstatus}: #{output}")
                end
	end


  	def create

   		repos = @resource[:repos]
   		groupid = @resource[:groupid]
   		artifactid = @resource[:artifactid]
   		version = @resource[:version]
   		packaging = @resource[:packaging]
   		classifier = @resource[:classifier]
   		directory = @resource[:directory]
   		user = @resource[:repos_user]
   		pass = @resource[:repos_pass]

   		# Where to copy the file from the local repository
   		dest = directory 

   		# Detect the correct URL of the artifact. SNAPSHOTS have a timestamped deployment, and releases can be referenced directly

   		debug "Repo:#{repos}"
   		debug "Groupid:#{groupid}"
   		debug "Art:#{artifactid}"
   		debug "version:#{version}"
   		debug "user:#{user}"
   		debug "pass:#{pass}"

  		artifactURL = ''
		
   		baseURL=repos + "/" + groupid.gsub(".","/") + "/" + artifactid + "/" + version

   		directURL = baseURL + "/" + artifactid + "-" + version + ".jar"
		
		is_reachable = is_reachable(directURL, user, pass)

   		if is_reachable	
   	 		artifactURL =  directURL 
   		else
       			# Artifact is a timestamped snapshot. Parse the metadata file and locate it
       			metadata = retrieve_metadata(repos,groupid,artifactid,version,user,pass)

       			value = extract_artifact_from_metadata(metadata)

       			artifactURL = baseURL + "/" + artifactid + "-" + value.to_s + ".jar"
	
		end

   		debug("Artifact found at: #{artifactURL}")

		final_name = "#{artifactid}-#{version}.jar"
		
		download_file(artifactURL, user, pass, dest, final_name)


  	end

  	def destroy
    		raise NotImplementedError
  	end

	def exists?
  	end
end
