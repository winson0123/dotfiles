#!/bin/bash

#|-----< Global Variables >-----|#
CLONE_DIR="/tmp"
ON_SUCCESS="LETSGOO"
ON_FAIL="WHYFAIL"
WHITE="\e[1;37m"
GREEN="\e[1;32m"
RED="\e[1;31m"
NC="\e[0m"

#|-----< Log File >-----|#
touch /tmp/foo.log

#|-----< Spinner >-----|#
_spinner() {
  # $1 start/stop
  #
  # on start: $2 - Display message
  # on stop : $2 - Process exit status
  #           $3 - Spinner function pid (supplied from stop_spinner)
  case $1 in
    start)
      echo -ne ":: ${2}  "

      # Start spin
      i=1
      sp="\|/-"
      delay=${SPINNER_DELAY:-0.15}

      while :
      do
        printf "\b${sp:i++%${#sp}:1}"
        sleep $delay
      done
      
      ;;
    stop)
      if [[ -z ${3} ]]; then
        echo "Spinner is not running ..."
        exit 1
      fi

      kill $3 > /dev/null 2>&1

      # Inform the user uppon success or failure
      echo -en "\b["
      if [[ $2 -eq 0 ]]; then
        echo -en "${GREEN}${ON_SUCCESS}${NC}"
      else
        echo -en "${RED}${ON_FAIL}${NC}"
      fi
      echo -e "]"
      ;;
    *)
      echo "Invalid argument, try {start/stop}"
      exit 1
      ;;
  esac
}

start_spinner() {
  # $1 : Msg to display
  _spinner "start" "${1}" &
  # Set global spinner pid
  _sp_pid=$!
  disown
}

stop_spinner() {
  # $1 : Command exit status
  _spinner "stop" $1 $_sp_pid
  unset _sp_pid
}

copy_configs() {
  if ! [ -d "$HOME/.config/i3" ]; then
    mkdir -p $HOME/.config/i3
  fi
  cp -r i3/* $HOME/.config/i3/

  if ! [ -d "$HOME/.config/polybar" ]; then
    mkdir -p $HOME/.config/polybar
  fi
  cp -r polybar/* $HOME/.config/polybar/

  if ! [ -d "$HOME/.config/rofi" ]; then
    mkdir -p $HOME/.config/rofi
  fi
  cp -r rofi/* $HOME/.config/rofi/

  if ! [ -d "$HOME/.local/share/wallpapers" ]; then
    mkdir -p $HOME/.local/share/wallpapers
  fi
  cp -r wallpapers/* $HOME/.local/share/wallpapers/
}

fonts_setup() {
  if ! [ -d "$HOME/.local/share/fonts" ]; then
    mkdir -p $HOME/.local/share/fonts
  fi
  cp -r fonts/* $HOME/.local/share/fonts/
  fc-cache -f
}

deps_ubuntu() {
  start_spinner "Updating sources list ..."

  # Linux Mint sources list
  if [ -d "/etc/apt/sources.list.d/official-package-repositories.list" ]; then
    sudo sed -i -e "s|packages.linuxmint.com|mirror.0x.sg/linuxmint|g" /etc/apt/sources.list.d/official-package-repositories.list
    sudo sed -i -e "s#\(archive\|security\)\.ubuntu\.com#mirror.sg.gs#g" -e "s|/ \+| |g" /etc/apt/sources.list.d/official-package-repositories.list
  
  # Ubuntu sources list
  else
    sudo sed -i -e "s#\(archive\|security\)\.ubuntu\.com#mirror.sg.gs#g" /etc/apt/sources.list 
  fi
  stop_spinner $?

  start_spinner "Updating system ..."
  sudo apt-get update >> /tmp/foo.log 2>&1
  stop_spinner $?

  start_spinner "Installing nala ..."
  sudo apt install -y nala >> /tmp/foo.log 2>&1
  stop_spinner $?
  echo -e ":: Nala installed [${GREEN}${ON_SUCCESS}${NC}]"

  #|-----< Installing necessary dependencies >-----|#
  start_spinner "Installing necessary dependencies ..."
  sudo nala install -y build-essential libgtk-3-dev apt-transport-https ca-certificates gnupg curl wget git python3 python3.10-venv neovim zsh lxappearance i3 i3lock polybar rofi feh copyq >> /tmp/foo.log 2>&1
  stop_spinner $?
  echo -e ":: Deps installed [${GREEN}${ON_SUCCESS}${NC}]"
}

vscode() {
  start_spinner "Installing VS Code ..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sudo sh -c "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list"
  rm -f /tmp/packages.microsoft.gpg
  sudo nala update >> /tmp/foo.log 2>&1
  sudo nala install -y code >> /tmp/foo.log 2>&1
  stop_spinner $?

  start_spinner "Installing VS Code extensions ..."
  code --install-extension Catppuccin.catppuccin-vsc >> /tmp/foo.log 2>&1
  code --install-extension Catppuccin.catppuccin-vsc-icons >> /tmp/foo.log 2>&1
  code --install-extension eamodio.gitlens  >> /tmp/foo.log 2>&1
  code --install-extension esbenp.prettier-vscode >> /tmp/foo.log 2>&1
  code --install-extension hoovercj.vscode-power-mode >> /tmp/foo.log 2>&1
  code --install-extension usernamehw.errorlens >> /tmp/foo.log 2>&1
  stop_spinner $?
  echo -e ":: VS Code installed [${GREEN}${ON_SUCCESS}${NC}]"
}

docker() {
  start_spinner "Installing Docker ..."
  wget -qO- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor > /tmp/docker.gpg
  sudo install -D -o root -g root -m 644 /tmp/docker.gpg /etc/apt/keyrings/docker.gpg
  sudo sh -c "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable' > /etc/apt/sources.list.d/docker.list"
  rm -f /tmp/docker.gpg
  sudo nala update >> /tmp/foo.log 2>&1
  sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> /tmp/foo.log 2>&1
  stop_spinner $?
  echo -e ":: Docker installed [${GREEN}${ON_SUCCESS}${NC}]"
}

programming_setup() {
  vscode
  docker
}

dragon_setup() {
  git clone https://github.com/mwh/dragon.git $CLONE_DIR/dragon/
  cd $CLONE_DIR/dragon
  make install
}

zoxide_setup() {
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  echo "\neval "$(zoxide init zsh)"" >> ~/.zshrc
}

zsh_setup() {
  curl -sSL https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo -E bash -s ${USER:=`whoami`}
  sed -i "s|jovial_parts\[margin-line\]="\\n"|jovial_parts[margin-line]=""|g" $HOME/.oh-my-zsh/custom/themes/jovial.zsh-theme
}

#|-----< Script start >-----|#
cat<<"EOF"

╔═════════════════════════════════════╗
║ _      ___          ___       __    ║
║| | /| / (_)__  _// / _ \___  / /____║
║| |/ |/ / / _ \(_-</ // / _ \/ __(_-<║
║|__/|__/_/_//_/ __/____/\___/\__/___/║
║              //                     ║
╚═════════════════════════════════════╝

EOF

#|-----< Check Distro >-----|#
DISTRO=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')

case $DISTRO in
  linuxmint | ubuntu | debian)
    echo -e ":: Distro found ${DISTRO}"
    deps_ubuntu
    ;;
  *)
    echo -e ":: ${RED}${DISTRO}{$NC} dotfiles haven't been explored yet :("
    exit 1
    ;;
esac

#|-----< Setup programming essentials >-----|#
programming_setup

#|-----< Setup zsh >-----|#
if ! [ -d "$HOME/.zsh" ];
then
  mkdir -p $HOME/.zsh
fi
start_spinner "Setting up zsh"
zsh_setup >> /tmp/foo.log 2>&1
stop_spinner $?

#|-----< Setup zoxide >-----|#
start_spinner "Setting up zoxide"
zoxide_setup >> /tmp/foo.log 2>&1
stop_spinner $?

#|-----< Setup dragon >-----|#
start_spinner "Setting up dragon"
dragon_setup >> /tmp/foo.log 2>&1
stop_spinner $?

#|-----< Configs >-----|#
start_spinner "Copying config files"
copy_configs >> /tmp/foo.log 2>&1
stop_spinner $?

#|-----< Fonts >-----|#
start_spinner "Copying fonts"
fonts_setup >> /tmp/foo.log 2>&1
stop_spinner $?

cat<<"EOF"

╔═════════════════════╗
║   ___               ║
║  / _ \___  ___  ___ ║
║ / // / _ \/ _ \/ -_)║
║/____/\___/_//_/\__/ ║
║                     ║
╚═════════════════════╝

EOF

