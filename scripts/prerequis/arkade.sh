#!/bin/bash
set -eo pipefail

find_home_profile(){
  if [[ -z "$HOME" ]]; then
    export user=$(whoami)
    export HOME=$(awk -F":" -v v="$user" '{if ($1==v) print $6}' /etc/passwd)
  fi

  if [[ "$SHELL" == *"/zsh" ]]; then
    HOME_PROFILE="$HOME/.zshrc"
  elif [[ "$SHELL" == *"/bash" ]]; then
    HOME_PROFILE="$HOME/.bashrc"
  fi
}

# Install Arkade
install_arkade(){
  LATEST_VERSION_URL="https://api.github.com/repos/alexellis/arkade/releases/latest"
  LATEST_VERSION=$(curl -s "${LATEST_VERSION_URL}" | grep '"tag_name":' | cut -d'"' -f4)
  DOWNLOAD_URL="https://github.com/alexellis/arkade/releases/download"

  if ! grep -qF "export PATH=\$PATH:\$HOME/.arkade/bin" "$HOME_PROFILE"; then
      printf "\e[1;33m[CHANGE]\e[m Appending arkade bin path to $HOME_PROFILE ...\n"
      mkdir -p $HOME/.arkade/bin
      echo "export PATH=\$PATH:\$HOME/.arkade/bin" >> "$HOME_PROFILE"
      echo "Export new PATH"
      export PATH=$PATH:$HOME/.arkade/bin
      #source $HOME_PROFILE
      echo ""
  else
      printf "\e[1;34m[INFO]\e[m ~/.arkade/bin path is already present in $HOME_PROFILE.\n"
      echo ""
  fi

  if [[ ! -f $HOME/.arkade/bin/arkade ]]; then
      printf "\e[1;33m[CHANGE]\e[m arkade is not found. Installing...\n"
      curl -L "${DOWNLOAD_URL}"/"${LATEST_VERSION}"/arkade --output $HOME/.arkade/new_arkade > /dev/null 2>&1
      mv $HOME/.arkade/new_arkade $HOME/.arkade/bin/arkade
      chmod +x $HOME/.arkade/bin/arkade
      CURRENT_VERSION=$(arkade version | grep 'Version:' | awk '{ print $2 }')
      printf "\e[1;32m[OK]\e[m arkade $CURRENT_VERSION has been installed.\n"
  else
      CURRENT_VERSION=$(arkade version | grep 'Version:' | awk '{ print $2 }')
      printf "\e[1;34m[INFO]\e[m arkade is already installed.\n"
      printf "\e[1;34m[INFO]\e[m Checking for updates...\n"
      if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
          printf "\e[1;33m[CHANGE]\e[m New version of arkade found, current: $CURRENT_VERSION. Updating...\n"
          curl -L "${DOWNLOAD_URL}"/"${LATEST_VERSION}"/arkade --output $HOME/.arkade/new_arkade > /dev/null 2>&1:
          mv $HOME/.arkade/new_arkade $HOME/.arkade/bin/arkade
          chmod +x $HOME/.arkade/bin/arkade
          printf "\e[1;32m[OK]\e[m arkade has been updated to version $CURRENT_VERSION.\n"
      else
          CURRENT_VERSION=$(arkade version | grep 'Version:' | awk '{ print $2 }')
          printf "\e[1;34m[INFO]\e[m arkade $CURRENT_VERSION is up-to-date.\n"
      fi
  fi
}

#Install arkade packages
install_pkg(){
  for line in $(cat ../../meta/ee-arkade.txt | egrep -v "#|^$" ); do
    if [[ ${line} != "arkade" ]]; then
      arkade get --progress=false ${line} > /dev/null || true
    fi
  done
  printf "\e[1;34m[INFO]\e[m Following packages were installed in ~/.arkade/bin : \n"
  ls -l $HOME/.arkade/bin
}

find_home_profile
install_arkade
install_pkg
