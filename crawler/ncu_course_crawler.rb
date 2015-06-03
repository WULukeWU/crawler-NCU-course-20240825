require 'crawler_rocks'
require 'pry'
require 'json'

class NcuCourseCrawler
  include CrawlerRocks::DSL

  DAYS = {
    "Mon" => 1,
    "Tue" => 2,
    "Wed" => 3,
    "Thu" => 4,
    "Fri" => 5,
    "Sat" => 6,
    "Sun" => 7,
  }

  PERIODS = {
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "Z" => 5,
    "5" => 6,
    "6" => 7,
    "7" => 8,
    "8" => 9,
    "9" => 10,
    "A" => 11,
    "B" => 12,
    "C" => 13,
    "D" => 14,
    "E" => 15,
    "F" => 16,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @query_url = "https://course.ncu.edu.tw/Course/main/query/byKeywords"

    @year = params && params["year"].to_i || year
    @term = params && params["term"].to_i || term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

  end

  def courses
    @courses = []
    @page_count = 1

    while true
      visit_page
      puts "page count: #{@page_count}"
      @page_count += 1

      @doc.css('table#item tbody tr').each do |row|
        datas = row.css("td")

        _url = datas[9] && datas[9].css('a')[0] && datas[9].css('a')[0][:onclick][25..-4]
        url = "https://course.ncu.edu.tw#{_url}"

        name = datas[1] && datas[1].text && datas[1].text.strip
        names = name.split(/\n+/)
        names.each {|d,i| d.strip!}
        names.each {|d| names.delete(d) if d.empty? }

        times = datas[4] && datas[4].text && datas[4].search('br').each {|d| d.replace("\n")} && datas[4].text.strip.split("\n")

        course_days = []
        course_periods = []
        course_locations = []
        if times
          times.each do |time|
            time.match(/(?<d>#{DAYS.keys.join('|')})(?<p>\d+)\/(?<loc>.+)/) do |m|
              m[:p].split("").each do |period|
                course_days << DAYS[m[:d]]
                course_periods << PERIODS[period]
                course_locations << m[:loc]
              end
            end
          end
        end


        @courses << {
          year: @year,
          term: @term,
          code: datas[0] && "#{@year}-#{@term}-#{datas[0].text}",
          name: names[1],
          english_name: names[0],
          lecturer: datas[2] && datas[2].text && datas[2].text.strip,
          credits: datas[3] && datas[3].text && datas[3].text.to_i,
          required: datas[5] && datas[5].text && datas[5].text.include?('必'),
          # semester: datas[6] && datas[6].text && datas[6].text.strip,
          outline: url,
          day_1: course_days[0],
          day_2: course_days[1],
          day_3: course_days[2],
          day_4: course_days[3],
          day_5: course_days[4],
          day_6: course_days[5],
          day_7: course_days[6],
          day_8: course_days[7],
          day_9: course_days[8],
          period_1: course_periods[0],
          period_2: course_periods[1],
          period_3: course_periods[2],
          period_4: course_periods[3],
          period_5: course_periods[4],
          period_6: course_periods[5],
          period_7: course_periods[6],
          period_8: course_periods[7],
          period_9: course_periods[8],
          location_1: course_locations[0],
          location_2: course_locations[1],
          location_3: course_locations[2],
          location_4: course_locations[3],
          location_5: course_locations[4],
          location_6: course_locations[5],
          location_7: course_locations[6],
          location_8: course_locations[7],
          location_9: course_locations[8],
        }
      end

      next_page = @doc.css('.pagelinks a:contains("»")')
      if next_page.empty?
        break
      else
        visit "https://course.ncu.edu.tw#{next_page[0][:href]}"
      end
    end

    File.write('courses.json', JSON.pretty_generate(@courses))
    @courses
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end

  def page_links
    @doc.css('.pagelinks a').map{|a| a.text} | @doc.css('.pagelinks strong').map{|a| a.text}
  end

  def visit_page
    visit "#{@query_url}?#{URI.encode(
      {
        "query" => "查詢",
        "fall_spring" => @term,
        "year" => @year-1911,
        "d-49489-p" => @page_count
      }.map {|k, v| "#{k}=#{v}"}.join('&'))}"
  end
end


cc = NcuCourseCrawler.new(year: 2014, term: 1)
cc.courses
