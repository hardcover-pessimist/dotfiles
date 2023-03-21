#!/bin/bash
base_git_dir=~/.local/src/configs
function _install_symlinks() {
  local files="
  ~/.bash_aliases
  ~/.bash_logout
  ~/.bash_profile
  ~/.bashrc
  ~/.dircolors
  ~/.inputrc
  ~/.profile
  ~/.tmux.conf
  ~/.zcompdump
  ~/.zpath
  ~/.zprofile
  ~/.zshenv
  ~/.zshrc
  ~/.zshrc.zni
  "
  for file in $files ;do
    file="${file/#~/$HOME}"
    if [ -e "$file" ];then
      if [ ! -L "$file" ];then
        rm -f "$file"
      fi
    fi
    if [[ ! -e $file ]];then
      filename=$(basename $file)
      echo "Installing symlink for $file"
      ln -s $base_git_dir/$filename $file
    fi
  done

  mkdir ~/.local/bin ~/.config -p
  echo "Installing symlink for ~/.local/bin/credentials-to-env"
  ln -s $base_git_dir/bin/credentials-to-env ~/.local/bin/credentials-to-env
  export PATH=~/.local/bin:$PATH
}

function _rbenv_install() {
  echo Installing Ruby version manager
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  export PATH="~/.rbenv/bin:$PATH"
  hash -r
  mkdir -p "$(rbenv root)"/plugins
  git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
}

function _install_deps() {
  sudo apt update
  sudo apt upgrade -y
  sudo apt-get remove -y --purge 'vim*'
  sudo apt install -y \
    libssl-dev \
    git \
    make \
    build-essential \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    curl \
    llvm \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    zip \
    unzip \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    libffi-dev \
    nano \
    keychain
}

function _pyenv_install() {
  echo Installing Python version manager
  curl https://pyenv.run | bash
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  pyenv install 3.10.2
  pyenv global 3.10.2
  curl -sSL https://install.python-poetry.org | python3 -
}

function _nvm_install() {
  echo Installing Node.js version manager
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
  export NVM_DIR=~/.nvm
  [ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh  # This loads nvm
  [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion  # This loads nvm bash_completion
  nvm install --lts
  source <(npm completion)
}

function _tfenv_install() {
  echo Installing Terraform version manager
  git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
}

function _rust_install() {
  echo Installing Rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path --profile default -y
  . ~/.cargo/env
}

function _install_aws_azure_login() {
  npm install -g aws-azure-login
  ln -s $(which aws-azure-login) ~/.local/bin/aws-azure-login
}

function _aws_install() {
  local tmpdir=$(mktemp -d)
  pushd $tmpdir
  curl -q "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  popd
  rm -rf $tmpdir
}
function _lazydocker_install() {
  echo Installing lazydocker
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
}

function _docker_install() {
  sudo apt-get remove docker docker-engine docker.io containerd runc -y
  sudo groupadd docker
  sudo usermod -aG docker ${USER}
  sudo mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  sudo apt-get update

  echo '%docker ALL = (root) NOPASSWD: /usr/bin/dockerd' | tee docker
  sudo cvtsudoers -f sudoers -o /etc/sudoers.d/docker docker
  rm docker
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo '{"hosts": ["unix:///mnt/wsl/shared-docker/docker.sock"], "iptables": false}' | sudo tee /etc/docker/daemon.json
}

function _alacrity_termcap() {
  wget https://github.com/alacritty/alacritty/releases/download/v0.11.0/alacritty.info
  sudo tic -xe alacritty,alacritty-direct alacritty.info
  infocmp alacritty
  rm alacritty.info
}

function _tflint_install() {
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
}

function _vim_install() {
  echo Installing Vim
  local base_dir=~/.config/nvim

  if ! type nvim; then
    if grep -P --quiet '(?<=ID_LIKE=)debian$' /etc/os-release; then
      wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb
      sudo apt install -y ./nvim-linux64.deb
      rm nvim-linux64.deb
      sudo update-alternatives --install /usr/local/bin/vim vim $(which nvim) 20
    fi
  fi

  if [[ ! -e $base_dir && -L ~/.bashrc ]];then
    pushd ~/.config && ln -s $(dirname $(realpath  ~/.bashrc))/.config/nvim .; popd
  fi

  if [ ! -d $base_dir/bundle/Vundle.vim ];then
    echo Installing Vundle
    git clone https://github.com/VundleVim/Vundle.vim.git $base_dir/bundle/Vundle.vim
  fi

  pyenv virtualenv 3.10.2 neovim3
  pyenv activate neovim3
  pip install neovim
  pyenv deactivate
  vim +PluginInstall +qall

  pushd $base_dir/bundle/plugins/flake8-vim/ftplugin/python/pycodestyle && git checkout main && git pull; popd

}
_install_deps

_install_symlinks

. ~/.bashrc

_alacrity_termcap
_rbenv_install
_pyenv_install
_nvm_install
_tfenv_install
_rust_install
_install_aws_azure_login
_aws_install
_docker_install
_lazydocker_install
_vim_install
_tflint_install

. ~/.bashrc
sudo locale-gen $LANG

echo startup ssh agent
/usr/bin/ssh-agent -s > ~/.agent;
echo Please restart terminal.
