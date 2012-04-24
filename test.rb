#!/usr/bin/ruby

require './util.rb'

# generate a random file with a sequential name.
filename = '.rnd'

sh "ruby uploader.rb #{filename} \"my file\" output.txt"
