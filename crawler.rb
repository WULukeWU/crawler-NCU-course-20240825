require 'nokogiri'
require 'pry'
require 'json'
require 'rest-client'

courses = []
r = RestClient.get "https://course.ncu.edu.tw/Course/main/query/byKeywords?query=%E6%9F%A5%E8%A9%A2&keyword=&fall_spring=1&year=103&day=&d-49489-p=1&selectDept=&week=1"
# change default language to Chinese
RestClient.get "https://course.ncu.edu.tw/Course/main/lang", cookies: r.cookies

(1..46).each do |page_number|
	string = nil

	if File.exist?("1031/#{page_number}.html")
		string = File.read("1031/#{page_number}.html")
	else
		url = "https://course.ncu.edu.tw/Course/main/query/byKeywords?query=%E6%9F%A5%E8%A9%A2&keyword=&fall_spring=1&year=103&day=&d-49489-p=#{page_number}&selectDept=&week=1"

		string = (RestClient.get url, cookies: r.cookies).to_s
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

    times = datas[4] && datas[4].text && datas[4].search('br').each {|d| d.replace("\n")} && datas[4].text.strip.split("\n")
    periods = []
    if times
      times.each do |time|
        m = time.match(/(?<d>Mon|Tue|Wed|Thu|Fri|Sat|Sun)(?<p>\d+)\/(?<loc>.+)/)
        if !!m
          m[:p].split("").each do |period|
            chars = []
            chars << m[:d]
            chars << period
            chars << m[:loc]
            periods << chars.join(',')
          end
        end
      end
    end


		courses << {
			code: datas[0] && datas[0].text,
			name: names[1],
      english_name: names[0],
			lecturer: datas[2] && datas[2].text && datas[2].text.strip,
			credits: datas[3] && datas[3].text && datas[3].text.to_i,
      periods: periods,
			required: datas[5] && datas[5].text && datas[5].text.strip,
			semester: datas[6] && datas[6].text && datas[6].text.strip,
			outline: url,
		}

	end
end

File.open('courses.json','w'){|file| file.write(JSON.pretty_generate(courses))}
