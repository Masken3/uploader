#!/usr/bin/ruby

# usage: uploader.rb <filename> "<description>"
# prints target URLs to stdout, one per line.

require './config.rb'
require 'net/http'
require 'uri'
require 'net/http/post/multipart'
require 'rubygems'	#required by nokogiri
require 'nokogiri'

INPUT_FILENAME = ARGV[0]
INPUT_DESCRIPTION = ARGV[1]
OUTPUT_FILENAME = ARGV[2]

def uptobox
	uptoboxType('uptobox.com')
end

def jumbofiles
	#uptoboxType('jumbofiles.com')
	# bug on www148, falling back to this one, which seems to work better.
	uptoboxType2('jumbofiles.com', 'www159.jumbofiles.com')
end

def uptoboxType(domain)
	# log in
	# not needed for uploads under 1024 MB

	# fetch the front page
	url = URI.parse("http://#{domain}/")
	req = Net::HTTP::Get.new(url.path)
	res = Net::HTTP.start(url.host, url.port) { |http|
		http.request(req)
	}
	#puts res.body
	# parse page, find wwwNumber.
	doc = Nokogiri::HTML(res.body)

	doc.xpath('//form').each do |form|
		if(form.attribute('name').value == 'file')
			url = form.attribute('action').value
			uri = URI.parse(url)
			p uri
			p uri.host
			uptoboxType2(domain, uri.host)
		end
	end
end

def outputUrl(url)
	puts url
	File.open(OUTPUT_FILENAME, 'a') do |file|
		file.puts url
	end
end

def uptoboxType2(baseDomain, uploadDomain)

	# send file by POST

	# 12-digit random number
	rando = ''
	(1..12).each do
		rando << rand(10).to_s
	end

	url = "http://#{uploadDomain}/cgi-bin/upload.cgi?upload_id=#{rando}&js_on=0&utype=anon&upload_type=file"
	puts url
	uri = URI.parse(url)
	File.open(INPUT_FILENAME) do |file|
		req = Net::HTTP::Post::Multipart.new(uri.path,
			'upload_type' => 'file',
			'sess_id' => '',
			'srv_tmp_url' => "http://#{uploadDomain}/tmp",
			'file_1' => UploadIO.new(file, 'application/octet-stream', INPUT_FILENAME),
			'file_1_descr' => INPUT_DESCRIPTION,
			'tos' => '1',
			'submit_btn' => '',
			)
		res = Net::HTTP.start(uri.host, uri.port) do |http|
			http.request(req)
		end
		p res
		p res.to_hash()
		p res.body
		resultUrl = res['location']
		puts resultUrl
		# parse url, get filename
		i = resultUrl.index('fn=') + 3
		id = resultUrl[i .. resultUrl.index('&', i)-1]
		outputUrl("http://#{baseDomain}/#{id}")
	end
end

def coolshare
	# fetch the front page
	url = URI.parse("http://www.coolshare.cz/")
	req = Net::HTTP::Get.new(url.path)
	res = Net::HTTP.start(url.host, url.port) { |http|
		http.request(req)
	}
	#puts res.body
	# parse page
	doc = Nokogiri::HTML(res.body)
	url = ''
	doc.xpath('//form').each do |form|
		if(form.attribute('id').value == 'nahrat-video-form')
			url = form.attribute('action').value
		end
	end

	# send file by POST

	puts url
	uri = URI.parse(url)
	File.open(INPUT_FILENAME) do |file|
		req = Net::HTTP::Post::Multipart.new(uri.path,
			'soubor' => UploadIO.new(file, 'application/octet-stream', INPUT_FILENAME),
			#'up_submit' => 'Uložit na server',
			'uID' => '',
			)
		res = Net::HTTP.start(uri.host, uri.port) do |http|
			http.request(req)
		end
		p res
		p res.to_hash()
		p res.body
		# parse body, get address
		key = '/upload-dokoncen/'
		i = res.body.index(key) + key.length
		id = res.body[i .. res.body.index('-', i)-1]
		outputUrl("http://www.coolshare.cz/stahnout/#{id}/")
	end
end

def rapidshare
	# get nextuploadserver.
	uri = URI.parse('http://api.rapidshare.com/cgi-bin/rsapi.cgi?sub=nextuploadserver')
	puts uri
	req = Net::HTTP::Get.new(uri.request_uri)
	res = Net::HTTP.start(uri.host, uri.port) { |http|
		http.request(req)
	}
	p res
	nus = res.body.strip

	# upload.
	url = "http://rs#{nus}.rapidshare.com/cgi-bin/rsapi.cgi"
	puts url
	uri = URI.parse(url)
	File.open(INPUT_FILENAME) do |file|
		req = Net::HTTP::Post::Multipart.new(uri.request_uri,
			'sub' => 'upload',
			'login' => CONFIG_RAPIDSHARE_LOGIN,
			'password' => CONFIG_RAPIDSHARE_PASSWORD,
			'filecontent' => UploadIO.new(file, 'application/octet-stream', INPUT_FILENAME),
			)
		res = Net::HTTP.start(uri.host, uri.port) do |http|
			http.request(req)
		end
		p res
		p res.to_hash()
		p res.body
		# parse body, get address
		key = "COMPLETE\n"
		i = res.body.index(key) + key.length
		id = res.body[i .. res.body.index(',', i)-1]
		outputUrl("https://rapidshare.com/files/#{id}/#{INPUT_FILENAME}")
	end
end

rapidshare
coolshare
uptobox
jumbofiles
