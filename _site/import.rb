require 'rubygems'
require 'nokogiri'
data = File.read 'ngauthier.com.xml'

doc = Nokogiri::XML(data)

doc.search('entry').each do |entry|
