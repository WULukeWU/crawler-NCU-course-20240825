require 'nokogiri'
require 'pry'
require 'json'
require 'rest-client'

courses = []
(1..46).each do |page_number|

	string = nil

	if File.exist?("1031/#{page_number}.html")
		string = File.read("1031/#{page_number}.html")
	else
		url = "https://course.ncu.edu.tw/Course/main/query/byKeywords?query=%E6%9F%A5%E8%A9%A2&keyword=&fall_spring=1&year=103&day=&d-49489-p=#{page_number}&selectDept=&week=1"

		string = (RestClient.get url).to_s
		File.open("1031/#{page_number}.html", 'w') {|f| f.write(string)}
	end
	
	document = Nokogiri::HTML(string)

	document.css('table#item tbody tr').each do |row|
		datas = row.css("td")


		#count = 10
		courses << {
			code: datas[0] && datas[0].text,
			name: datas[1] && datas[1].text,
			lecturer: datas[2] && datas[2].text,
			credits: datas[3] && datas[3].text,
			classroom_time: datas[4] && datas[4].text,
			required: datas[5] && datas[5].text,
			semester: datas[6] && datas[6].text,
			outline: datas[9] && datas[9].css('a')[0] && datas[9].css('a')[0][:onclick],
		}

	end
end

File.open('courses.json','w'){|file| file.write(JSON.pretty_generate(courses))}
binding.pry
puts "asdf"