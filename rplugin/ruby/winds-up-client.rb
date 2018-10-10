require 'neovim'
require_relative '../../lib/winds-up-client'
Neovim.plugin do |plug|
  client = WindsUpClient.new(lpass: true, ultrashort: true)
  plug.command(:WindsUp) do |nvim|
    nvim.set_var "windsup", client.favorites_spots_text.chomp
  end
end
