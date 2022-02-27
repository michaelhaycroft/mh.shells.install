SHELLS_INSTALL_ROOT="/mh.shells" # INSERT THE TARGET PATH FOR INSTALLATION HERE
INSTALL_PACKAGES="1"
GIT_INSTALL_ERROR="0"
[[ ! -z "$(which git)" ]] || sudo dnf install -y git-all || sudo apt install -y git-all || GIT_INSTALL_ERROR="1"
if [[ "$GIT_INSTALL_ERROR" == "1" ]]; then
  echo "Install Git using a package manager available on your system and run again."
else
  read -p "Enter a passphrase for Github SSH (e.g. empty string): " GITHUB_SSH_PASSPHRASE
  read -p "Enter github user email: " GITHUB_USER_EMAIL
  GITHUB_SSH_KEY_OUTFILE="$HOME/.ssh/github_$(echo $GITHUB_USER_EMAIL | sed 's/\./dot/g' | sed 's/@/at/g')"
  ssh-keygen -t ed25519 -C $GITHUB_USER_EMAIL -f $GITHUB_SSH_KEY_OUTFILE < <(echo -e "$GITHUB_SSH_PASSPHRASE\n$GITHUB_SSH_PASSPHRASE\n")
  cat $GITHUB_SSH_KEY_OUTFILE.pub
  echo "UPLOAD THE ABOVE GENERATED SSH PUBLIC KEY ($GITHUB_SSH_KEY_OUTFILE) TO GITLAB THEN PRESS ANY KEY TO CONTINUE"
  read
  PARENT_DIR="$(dirname "$SHELLS_INSTALL_ROOT")"
  sudo mkdir -p "$PARENT_DIR"
  sudo chown $USER "$PARENT_DIR"
  pushd $PARENT_DIR
  git clone git@github.com:michaelhaycroft/mh.shells.git
  popd
  sudo chown $USER $SHELLS_INSTALL_ROOT -R
  sudo chmod u+x $SHELLS_INSTALL_ROOT -R
  if [[ "$INSTALL_PACKAGES" == "1" ]]; then
    [[ ! -z "$(which datamash)" ]] || sudo dnf install datamash || sudo apt install datamash || echo "Error: failed to install datamash" # The install framework requires datamash
    bash "$SHELLS_INSTALL_ROOT/linux/scripts/install.sh"
  fi
fi
