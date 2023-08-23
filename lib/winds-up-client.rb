#!/bin/env ruby
require 'mechanize'
require 'date'
require 'json'
require 'yaml'
require 'paint'

class TerminalTable 

	def initialize attributes
		@rows = attributes[:rows]
	end

	def to_s
    return "" if @rows.size == 0
    widths = @rows.reduce(@rows[0].size.times.to_a.map { 0 } ) { |memo, row| memo.each_with_index.map { |item, i| [row.size > i ? row[i].size : 0, item].max } }
    @rows.map do |row|
      row.each_with_index.map { |item, i| "#{item}#{" " * (widths[i] - item.size)}" }.join(" ")
    end.join("\n")
	end
end

class WindsUpClient

  def lpass what
    `lpass show --#{what} winds-up.com`.chomp
  end

  def rbw what
    `rbw get --raw winds-up.com | jq -r .data.#{what}`.chomp
  end

  def initialize options
    @options = options
    @options.merge!({username: lpass(:username), password: lpass(:password)}) if @options[:lpass]
    @options.merge!({username: rbw(:username), password: rbw(:password)}) if @options[:bitwarden]
  end

  def parse_series spot
    Hash[[:actual, :expected].zip(spot.search("script").map do |script|
      JSON.parse(script.children[0].text.encode("utf-8", invalid: :replace, undef: :replace).match(/data: \[.*\]/)[0].gsub("data:", "").gsub(",}", "}").gsub(/(\w+):/, '"\1":'))
    end)]
  end

  def parse_spot spot
    {
			title: spot.search("a.title").map { |title| title.children.text }[0],
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

  def bar size, alternate, bg
    if !@options[:nocolor]
      Paint[(" " * size), nil, bg]
    else
      alternate * size
    end
  end

  def low size
    bar size, "=", :blue
  end

  def high size
    bar size, "-", :green
  end

  def expected size
    bar size, "*", :yellow
  end

  def to_arrows(cardinals)
    return "?" if cardinals.nil?
    {
      se: "↖",
      so: "↗",
      no: "↘",
      ne: "↙",
    }.map { |name, value|
      cardinals.sub!(name.to_s.upcase, value)
    }
    {
      e: "←",
      s: "↑",
      o: "→",
      n: "↓",
    }.map { |name, value|
      cardinals.sub!(name.to_s.upcase, value)
    }
    cardinals
  end
  def series_handlers
    {
      actual: (-> (x) {"#{low(x["low"])}#{high(x["high"] - x["low"])} #{(x["high"] + x["low"])/2}"}),
      expected: (-> (x) {"#{ expected(x["y"])} #{x["y"]} #{to_arrows(x["o"])}"})
    }
  end

  def send_metric time, spot, name, value, time_shift = 0
    payload = "windsup.#{spot[:title].encode!('UTF-8', 'UTF-8', :invalid => :replace, :replace => '').force_encoding('ascii').gsub(" ", "-").downcase}.#{name} #{value} #{time / 1000 + time_shift}\n"
    socket = TCPSocket.new(@options[:ghost], @options[:gport] || 2003)
    socket.write(payload)
    socket.flush
    socket.close
  end

  def send_orientation value_x, value, spot, metric, time_shift = 0
    if not value.nil?
      mapping = { N: 0, NNE: 22.5, NE: 45, ENE: 77.5, E: 90, ESE: 112.5, SE: 135, SSE: 157.5, S: 180, SSO: 202.5, SO:225, OSO: 247.5, O: 270, ONO: 292.5, NO: 315, NNO: 337.5}
      send_metric value_x, spot, metric, mapping[value.to_sym], time_shift
    end
  end

  def graphite_write spot
    wind = spot[:wind].split(" ")
    send_orientation (Time.now.to_i - 20) * 1000, wind[2], spot, "actual.o"
    spot[:series][:actual].each do |value|
      ["low", "high"].each { |t| send_metric value["x"], spot, "actual.#{t}", value[t] }
    end
    spot[:series][:expected].each do |value|
      dt = -(3 * 24 * 60 * 60)
      ["y", "o"].each { |t| send_metric value["x"], spot, "expected.#{t}", value[t], dt }
      send_orientation value["x"], value["o"], spot, "expected.o", dt
    end
  end

  def spot_row spot
    graphite_write spot if @options[:ghost]
    title = [spot[:title], to_arrows(spot[:wind])]
    i = 0
    rows = []
    rows << title
    series_handlers.each do |kind, handler|
      spot[:series][kind].each do |value|
        rows << [Time.at(value["x"] / 1000).to_datetime.to_s.gsub(/\+.*/, ""), handler.call(value)] if i % @options[:sampling] == 0
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

  def favorites_spots_text
    result = ""
    spots = favorites_spots
    previous_rows = []
    spots.each_with_index do |spot, i|
			if @options[:spot].nil? or spot[:title].downcase.include?(@options[:spot])
				if @options[:short]
					result += "#{spot[:title]}: #{to_arrows(spot[:wind])}\n"
        elsif @options[:ultrashort]
          result += "#{spot[:title][0]}#{to_arrows(spot[:wind]).sub(" nds", "").sub(" ", "")}"
				else
					rows = spot_row spot
					if i % 2 == 1
            result += TerminalTable.new(:rows => join_rows(previous_rows, rows)).to_s
            result += "\n"
					end
					previous_rows = rows
				end
			end
    end
    result += TerminalTable.new(:rows => previous_rows).to_s if spots.size % 2 == 1 and !@options[:short]
    result + "\n"
  end

  def favorites_spots_text_with_cache
    path = "#{ENV['HOME']}/.local/share/winds-up-client.cache"
    if not File.exists?(path) or Time.now - File.mtime(path) > 60
      File.write(path, favorites_spots_text)
    end
    File.read(path)
  end

  def display_favorite_spots
    if @options[:cache]
      puts favorites_spots_text_with_cache
    else
      puts favorites_spots_text
    end
  end
end
