#!/usr/bin/ruby

# usage: uploader.rb <filename> "<description>"
# prints target URLs to stdout, one per line.

require './config.rb'
require 'net/http'
require 'uri'
require 'net/http/post/multipart'

INPUT_FILENAME = ARGV[0]
INPUT_DESCRIPTION = ARGV[1]
OUTPUT_FILENAME = ARGV[2]

def uptobox
	# log in
	# not needed for uploads under 1024 MB

	# fetch the front page
	#url = URI.parse('http://uptobox.com/')
	#req = Net::HTTP::Get.new(url.path)
	#res = Net::HTTP.start(url.host, url.port) { |http|
	#	http.request(req)
	#}
	#puts res.body

	# send file by POST

	# 12-digit random number
	rando = ''
	(1..12).each do
		rando << rand(10).to_s
	end

	url = "http://www8.uptobox.com/cgi-bin/upload.cgi?upload_id=#{rando}&js_on=0&utype=reg&upload_type=file"
	puts url
	uri = URI.parse(url)
	File.open(INPUT_FILENAME) do |file|
		req = Net::HTTP::Post::Multipart.new(uri.path,
			'upload_type' => 'file',
			'sess_id' => '',
			'srv_tmp_url' => 'http://www8.uptobox.com/tmp',
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
		finalUrl = 'http://uptobox.com/' + id
		puts finalUrl
		File.open(OUTPUT_FILENAME, 'a') do |file|
			file.puts finalUrl
		end
	end
end

uptobox
