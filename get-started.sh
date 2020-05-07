#!/bin/bash
set -u
set -e
sudo -v

update_shell() {
  local shell_path;
  shell_path="$(which zsh)"

  echo "Changing your shell to zsh ..."
  if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
    echo "Adding '$shell_path' to /etc/shells"
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi
}


# ----------------------------------------
# 1. Introduction
# ----------------------------------------
echo "
----------------------------------------
🎉 Welcome to the team! It's great to have you here.

This script will install everything required to get started at Linktree. If you encounter any problems during the process, please file an Issue here:
https://github.com/linktr-ee/bootstrap.linktr.ee

If you feel confident you can fix the problem, please feel free to submit a Pull Request with your fix.
https://github.com/linktr-ee/bootstrap.linktr.ee/pulls
----------------------------------------
"

# ----------------------------------------
# 2. Install homebrew & zsh.
# ----------------------------------------
if test ! $(which brew)
then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Ensure non-super users can continue.
sudo chown -R $(whoami) $(brew --prefix)/*

# Ensure chsh can access the zsh installation
case "$SHELL" in
  */zsh)
    if [ "$(which zsh)" != '/bin/zsh' ] ; then
      update_shell
    fi
    ;;
  *)
    update_shell
    ;;
esac

chsh -s $(which zsh)

# ----------------------------------------
# 3. Install Python & Python Dependencies.
# ----------------------------------------
declare pythonVersion=3.7.6
declare ansibleVersion=2.9

brew upgrade pyenv || true
brew install pyenv || true

pyenv install "${pythonVersion}"
pyenv global "${pythonVersion}"

# Ensure pyenv is initialized and set in zsh
# @todo - Only echo this command into zshrc if it doesn't exist to prevent multiples on failed attempts.
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc

# @todo - Only echo this command into zshrc if it doesn't exist to prevent multiples on failed attempts.
echo -e "PATH=$PATH:$HOME/.local/bin" >> ~/.zshrc
source ~/.zshrc

# Install Ansible
pip3 install -q --upgrade --user pip virtualenv virtualenvwrapper
pip3 install -q --user ansible==${ansibleVersion} paramiko wheel

# ----------------------------------------
# 4. Run Playbook
# ----------------------------------------
if test ! $(which ansible-galaxy)
then
    echo "
    Ansible Galaxy cannot be found. Please report this as a bug.
    https://github.com/linktr-ee/bootstrap.linktr.ee/issues3
    "
fi

# Ensure gatekeeper is disabled.
sudo spctl --master-disable

# Run the playbook.
ansible-galaxy install -r ./requirements.yml
ansible-playbook playbook.yml

# Ensure gatekeeper is enabled.
sudo spctl --master-enable


# ----------------------------------------
# 5. Get Started
# ----------------------------------------
open /Applications/Docker.app
open /Applications/Slack.app
