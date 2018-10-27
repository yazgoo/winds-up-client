require 'neovim'
require_relative '../../lib/winds-up-client'
Neovim.plugin do |plug|
  client = WindsUpClient.new(lpass: true, ultrashort: true)
  last_check = nil
  plug.command(:WindsUp) do |nvim|
    if last_check.nil? or Time.new - last_check > 60 
      begin
        nvim.set_var "windsup", client.favorites_spots_text.chomp
      rescue Exception
      end
      last_check = Time.new
    end
  end
end
