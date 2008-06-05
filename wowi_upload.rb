#! /c/ruby/bin/ruby

require 'net/http'
require 'uri'
require 'digest/md5'
require 'xmlsimple'


#########################
##      Multipart      ##
#########################

module Multipart
  # From: http://deftcode.com/code/flickr_upload/multipartpost.rb
  ## Helper class to prepare an HTTP POST request with a file upload
  ## Mostly taken from
  #http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/113774
  ### WAS:
  ## Anything that's broken and wrong probably the fault of Bill Stilwell
  ##(bill@marginalia.org)
  ### NOW:
  ## Everything wrong is due to keith@oreilly.com
  require 'rubygems'
  require 'mime/types'
  require 'net/http'
  require 'cgi'

  class Param
    attr_accessor :k, :v
    def initialize( k, v )
      @k = k
      @v = v
    end

    def to_multipart
      #return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"\r\n\r\n#{v}\r\n"
      # Don't escape mine...
      return "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
    end
  end

  class FileParam
    attr_accessor :k, :filename, :content
    def initialize( k, filename, content )
      @k = k
      @filename = filename
      @content = content
    end

    def to_multipart
      #return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n "
      # Don't escape mine
      return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
    end
  end
  class MultipartPost
    BOUNDARY = 'tarsiers-rule0000'
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}

    def prepare_query (params)
      fp = []
      params.each {|k,v|
        if v.respond_to?(:read)
          fp.push(FileParam.new(k, v.path, v.read))
        else
          fp.push(Param.new(k,v))
        end
      }
      query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end
end

######################


credentials = File.read("c:\\Users\\Tekkub\\.wowicreds.txt")
username, password = $1, $2 if credentials =~ /\A(.+)\n(.+)\Z/

unless username && password
	puts "Could not find username and password"
	exit 1
end


addon_name, new_version, zip_file, changelog_file, description_file = $*
unless addon_name && new_version && zip_file && changelog_file && description_file
	puts "Usage: addon_name, new_version, zip_file, changelog_file, description_file"
	exit 1
end


changelog = File.read(changelog_file)
description = File.read(description_file)


def urlencode(str)
	str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
end


url = URI.parse("http://www.wowinterface.com/forums/login.php")
Net::HTTP.start("www.wowinterface.com") do |http|
	puts "Logging in as #{username}"

	params = {
		"vb_login_username" => username,
		"vb_login_password" => password,
		"cb_cookieuser_navbar" => "1",
		"forceredirect" => "1",
		"do" => "login"
	}
	req = Net::HTTP::Post.new("/forums/login.php")
	req.body = params.map {|k,v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }.join('&')
	req.content_type = 'application/x-www-form-urlencoded'
	res = http.request req

	if res.body =~ /You have used up your failed login quota/
		puts res.body
		puts "Your account has been locked out for 15 minutes due to an invalid password"
		exit 1
	elsif res.body =~ /You have entered an invalid username or password/
		puts "Invalid username or password"
		exit 1
	elsif res.body =~ /Thank you for logging in/
		puts "Login successful"
		session = $1 if res.body =~ /s=([a-z0-9]+)"/
	else
		puts res.body
		puts "Unknown login error"
		exit 1
	end

	unless session
		puts "Cannot create edit session"
		exit 1
	end

	password = Digest::MD5.hexdigest(password)


	res = http.get("/downloads/editfile_xml.php?do=listfiles&l=#{username}&p=#{password}")
	xml_in = XmlSimple.xml_in(res.body)
	addon_id = xml_in["id"][xml_in["title"].index(addon_name)]
	unless addon_id
		puts "Error finding WoWI addon ID"
		exit 1
	end

	file = File.open(zip_file, "rb")

	params = {
		"op" => "editfile",
		"type" => "0",
		"mode" => "0",
		"wgp" => "1",
		"allowpa" => "1",
		"fileaction" => "replace",
		"sbutton" => "Update",
		"ftitle" => addon_name,
		"id" => addon_id,
		"s" => session,
		"version" => new_version,
		"message" => description,
		"changelog" => changelog,
		"replacementfile" => file,
	}

	mp = Multipart::MultipartPost.new
	query, headers = mp.prepare_query(params)
	file.close

	res = http.post("/downloads/editfile.php", query, headers)

	if res.body =~ /The file has been updated/
		puts "Upload successful"
	else
		puts res.body
		puts "Error uploading file"
	end
end
