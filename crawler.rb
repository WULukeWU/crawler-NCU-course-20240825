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

    append = datas[9] && datas[9].css('a')[0] && datas[9].css('a')[0][:onclick][25..-4]
    url = "https://course.ncu.edu.tw#{append}"

		name = datas[1] && datas[1].text && datas[1].text.strip
    names = name.split(/\n+/)
    names.each {|d,i| d.strip!}
    names.each {|d| names.delete(d) if d.empty? }

		courses << {
			code: datas[0] && datas[0].text,
			name: names[1],
      english_name: names[0],
			lecturer: datas[2] && datas[2].text && datas[2].text.strip,
			credits: datas[3] && datas[3].text && datas[3].text.to_i,
			classroom_time: datas[4] && datas[4].text && datas[4].text.strip,
			required: datas[5] && datas[5].text && datas[5].text.strip,
			semester: datas[6] && datas[6].text && datas[6].text.strip,
			outline: url,
		}

	end
end

File.open('courses.json','w'){|file| file.write(JSON.pretty_generate(courses))}
