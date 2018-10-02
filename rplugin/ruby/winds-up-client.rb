require 'winds-up-client'
require 'neovim'

Neovim.plugin do |plug|
  plug.command(:WindsUp, nargs: 1) do |nvim, arg|
    nvim.set_var "windsup", WindsUpClient.new(lpass: true, ultrashort: true).favorites_spots_text.chomp
  end
end
