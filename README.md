# examples

Display your favorites spots:

```shell
$ winds-up-client --user blah --password blah
```

Display a summary of your favorites spots, loging in with lastpass-cli:

```shell
$ winds-up-client --lpass --short
```

Display an ultrashort summary of your favorites spots (wind speed, wind direction, first letter of each spot):

```shell
$ winds-up-client --lpass --ultrashort
B19↓S9↓P17↘S?V5↓
```
# neovim plugin

install neovim gem:

```shell
$ gem install neovim
```

Add to your vim config this repo as a plugin (here for vimplug):
```vimscript
Plug 'yazgoo/winds-up-client', { 'do' : ':UpdateRemotePlugins' }
```

This adds `:WindsUp` command which will set `g:windsup` variable to an ultrashort wind report.
