#!/bin/env ruby
require 'mechanize'
require 'date'
require 'json'
require 'terminal-table'

class WindsUpClient

  def lpass what
    `lpass show --#{what} winds-up.com`.chomp
  end

  def initialize options
    @options = options
    @options.merge!({username: lpass(:username), password: lpass(:password)}) if @options[:lpass]
  end

  def parse_series spot
    Hash[[:actual, :expected].zip(spot.search("script").map do |script|
      JSON.parse(script.children[0].text.match(/data: \[.*\]/)[0].gsub("data:", "").gsub(",}", "}").gsub(/(\w+):/, '"\1":'))
    end)]
  end

  def parse_spot spot
    {
      title: spot.search("a.title").map { |title| title.children.text },
      wind: spot.search("div.infosvent2").map { |info| info.children[1].text }[0],
      series: parse_series(spot)
    }
  end

  def favorites_spots 
    agent = Mechanize.new
    website = 'https://www.winds-up.com'
    page = agent.get(website)
    form = page.form('formu_login')
    form["login_pseudo"] = @options[:username]
    form["login_passwd"] = @options[:password]
    agent.submit(form)
    page = agent.get(website + '/index.php?p=favoris')
    spots = page.search("div.mt3").reverse.map { |spot| parse_spot spot }
  end

  def series_handlers
    {
      actual: (-> (x) {"#{"=" * x["low"]}#{"-" * (x["high"] - x["low"])} #{(x["high"] + x["low"])/2}"}),
      expected: (-> (x) {"#{ "*" * x["y"]} #{x["y"]} #{x["o"]}"})
    }
  end

  def spot_row spot
    title = [spot[:title], spot[:wind]]
    i = 0
    sampling = 2
    rows = []
    rows << title
    series_handlers.each do |kind, handler|
      spot[:series][kind].each do |value|
        rows << [Time.at(value["x"] / 1000).to_datetime.to_s.gsub(/\+.*/, ""), handler.call(value)] if i % sampling == 0
        i += 1
      end
    end
    rows << title
  end

  def join_rows_ordered a, b
    a.each_with_index.map do |a_row, i|
      i < b.size ? a_row + b[i] : a_row
    end
  end

  def join_rows a, b
    a.size > b.size ? join_rows_ordered(a, b) : join_rows_ordered(b, a)
  end

  def display_favorite_spots
    spots = favorites_spots
    previous_rows = []
    spots.each_with_index do |spot, i|
      if @options[:short]
        puts "#{spot[:title]}: #{spot[:wind]}"
      else
        rows = spot_row spot
        if i % 2 == 1
          puts Terminal::Table.new :rows => join_rows(previous_rows, rows)
        end
        previous_rows = rows
      end
    end
    puts Terminal::Table.new :rows => previous_rows if spots.size % 2 == 1 and !@options[:short]
  end
end

WindsUp.new(Trollop::options do
  opt :short
  opt :lpass
  opt :user, "user", :type => :string
  opt :password, "password", :type => :string
end).display_favorite_spots
