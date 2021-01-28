# Dotfiles
This repo holds my personal dotfiles for my own convenience. Feel free to pick and choose whatever suits your needs. I am currently on **Arch Linux with the Gnome desktop environment**, but the majority of these files will work fine on any Linux distro, as well as Mac OS.

## Organization
### .dotfiles/home/
The actual dotfiles are in the `home` directory, in the exact same path they would be in the local home directory. This is mostly for convenience; easier symlinking and keeping other files apart.

With this structure symlinking is very straightforward, as well as easy to automate (see dotty). Simply find the file in `~/.dotfiles/home/`, and link against the same path with `.dotfiles/home/` removed. For example:
```bash
# ln -vs <source> <destination>
ln -vs ~/.dotfiles/home/.zshrc ~
ln -vs ~/.dotfiles/home/.config/Code/User/settings.json ~/.config/Code/User/
```

### .dotfiles/lists/
Plain text lists for automation purposes. One entry per line.

<details>
<summary><b>VScode extensions</b></summary>

* Install vscode extensions from list:
  ```
  cat ~/.dotfiles/lists/vscode-extensions.list | xargs -L1 code --install-extension
  ```

* Generate a new list from installed extensions:
  ```
  code --list-extensions > ~/.dotfiles/lists/vscode-extensions.list
  ```
</details>
&nbsp;

<details>
<summary><b>Arch package installs</b></summary>

* Install pacman packages from a list without reinstalling previously installed ones:
  ```
  sudo pacman -Syu --needed - < ~/.dotfiles/lists/pacman-userprogs.list
  ```

* Install AUR packages from a list without reinstalling previously installed ones:
  ```
  yay -Syu --needed - < ~/.dotfiles/lists/aur-packages.list
  ```
</details>
&nbsp;

<details>
<summary><b>Mac package installs</b></summary>

* Install brew packages from a list:
  ```
  xargs brew install < brew-packages.list
  ```

* Install brew cask (GUI) packages from a list:
  ```
  xargs brew install --cask < brew-cask-packages.list
  ```
</details>
&nbsp;

Etc.

### .dotfiles/scripts/
Executable scripts. Do not forget to, you know, make them executable:
```
chmod u+x /home/david/.dotfiles/scripts/whatever
```

Also, for the aliases to work, you'll need to add the `scripts` directory to your path.
(In this repo that is done with the `path_append` function in zshrc.)

## Overview of symlinks
* `~`:
  ```bash
  # zshrc, vimrc, gitconfig:
  ln -vsf ~/.dotfiles/home/.zshrc ~
  ln -vsf ~/.dotfiles/home/.vimrc ~
  ln -vsf ~/.dotfiles/home/.gitconfig ~

  # Templates directory:
  rm ~/Templates
  ln -vsf ~/.dotfiles/home/Templates ~
  ```

* `~/.config/`:
  ```bash
  # VScode:
  ln -vsf ~/.dotfiles/home/.config/Code/User/settings.json ~/.config/Code/User

  # MPV scripts and configs:
  ln -vsf ~/.dotfiles/home/.config/mpv/scripts/autosub/autosub.lua ~/.config/mpv/scripts
  ln -vsf ~/.dotfiles/home/.config/mpv/input.conf ~/.config/mpv
  ln -vsf ~/.dotfiles/home/.config/mpv/mpv.conf ~/.config/mpv

  # NeoVIM:
  ln -vsf ~/.dotfiles/home/.config/nvim/init.vim ~/.config/nvim

  # Tridactyl Firefox addon:
  ln -vsf ~/.dotfiles/home/.config/tridactyl/tridactylrc ~/.config/tridactyl

  # Home "User directories" customizations:
  ln -vsf ~/.dotfiles/home/.config/user-dirs.dirs ~/.config
  ```

* `~/.oh-my-zsh/`:
  ```bash
  ln -vsf ~/.dotfiles/home/.oh-my-zsh/custom/base.zsh ~/.oh-my-zsh/custom
  ln -vsf ~/.dotfiles/home/.oh-my-zsh/custom/gpg.zsh ~/.oh-my-zsh/custom
  ln -vsf ~/.dotfiles/home/.oh-my-zsh/custom/plugins/git ~/.oh-my-zsh/custom/plugins
  ```

Note that the `-f, --force` flag will remove existing files, so if you're not on a brand new system, make sure important files are moved to safety first. Also, on a new system some of these directories will still have to be created.

## Overview of submodules
```
git submodule add git@github.com:davidde/git.git home/.oh-my-zsh/custom/plugins/git
git submodule add git@github.com:davidde/mpv-autosub.git home/.config/mpv/scripts/autosub
```