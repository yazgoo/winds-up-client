require 'winds-up-client'
require 'neovim'

Neovim.plugin do |plug|
  plug.command(:WindsUp) do |nvim|
    nvim.set_var "windsup", WindsUpClient.new(lpass: true, ultrashort: true).favorites_spots_text.chomp
  end
end
