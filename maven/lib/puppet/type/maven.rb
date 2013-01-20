require 'puppet/type'

Puppet::Type.newtype(:maven) do
  require 'timeout'

  @doc = "Maven repository files."

  ensurable do
    self.defaultvalues
    defaultto :present
  end

  def self.title_patterns
    [ [ /^(.*?)\/*\Z/m, [ [ :path, lambda{|x| x} ] ] ] ]
  end

  newparam(:path) do
    desc "The destination path of the downloaded file."
    isnamevar
  end

  newparam(:directory) do
    desc "The destination path of the downloaded file."
  end

  newparam(:groupid) do
    desc "The Maven arifact group id, ie. 'org.apache.maven'"
  end
  newparam(:artifactid) do
    desc "The Maven artifact id, ie. 'maven-core'"
  end
  newparam(:version) do
    desc "The Maven artifact version, ie. '2.2.1'"
  end
  newparam(:packaging) do
    desc "The Maven artifact packaging, ie. 'jar'"
  end
  newparam(:classifier) do
    desc "The Maven artifact classifier, ie. 'sources'"
  end
  newparam(:repos) do
    desc "Repositories to use for artifact downloading. Defaults to http://repo1.maven.apache.org/maven2"
  end
  newparam(:timeout) do
    desc "Download timeout."
  end

  newparam(:repos_user) do
    desc "User to access the repository in case it needs"
  end
  newparam(:repos_pass) do
    desc "Password to access the repository in case it needs"
  end

  validate do
    groupid = self[:groupid]
    artifactid = self[:artifactid]
    version = self[:version]
    packaging = self[:packaging]
    classifier = self[:classifier]

    if(groupid.nil? || artifactid.nil? || version.nil?)
	self.fail "Must specify GAV coordinates"
    end

  end

end
