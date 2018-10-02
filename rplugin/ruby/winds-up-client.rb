require 'neovim'

Neovim.plugin do |plug|
  plug.command(:WindsUp, nargs: 1) do |nvim, arg|
    nvim.set_var "windsup", "a"#WindsUpClient.new(lpass: true, ultrashort: true).favorites_spots_text.chomp
  end
end
