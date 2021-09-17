#!/bin/bash

set -eu

[[ "$OSTYPE" = "linux"* ]] || echo -e "\nThis script must be run on GNU/Linux. Aborting...\n" || exit 1

read -p "This script will install all the demo software of team WEEE Open with its necessary dependencies. Do you want to proceed? [y/N] " PROCEED
[[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]] || echo -e "\nAborting...\n" || exit 0

# Arch vs Debian -based detection
[[ -f /etc/debian_version ]] && DISTRO_BASE="debian" || DISTRO_BASE="arch"
[[ $EUID = 0 ]] && SUDO="" || SUDO="sudo"
GH_URL="https://github.com/weee-open/"
DEPS="git make docker.io docker-compose pciutils i2c-tools mesa-utils smartmontools dmidecode python3 python3-venv cloc"
TARALLO_URL="http://localhost:8080"
WEEEHIRE_URL="http://localhost:8777"

echo -e "\nUpdating local repos...\n"
if [[ "$DISTRO_BASE" = "debian" ]]; then 
	$SUDO apt update || true
else
	$SUDO pacman -Syy || true
fi

echo -e "\nInstalling global dependencies...\n"
if [[ "$DISTRO_BASE" = "debian" ]]; then
	$SUDO apt install -y $DEPS
else
	$SUDO pacman -Sy $DEPS
fi

if [[ ! "$(groups)" = *"docker"* ]]; then
	# docs here: https://docs.docker.com/engine/install/linux-postinstall/
	echo -e "\nEnabling user to run docker without sudo (first time only)...\n"
	# $SUDO groupadd docker || true
	[[ $EUID != 0 ]] && $SUDO usermod -aG docker $USER
	newgrp docker
fi

function git_error() {
	echo -e "\nThere was an error with git clone, aborting...\n"
	exit 2
}

# remove existing directory
function rm_x_dir() {
	[[ -d "$1" ]] && rm -rf "$1" || true  # true needed to keep running if dir does not exist
}

echo -e "\nInstalling T.A.R.A.L.L.O (Tuttofare Assistente il Riuso di Aggeggi Logori e Localmente Opprimenti)...\n"
rm_x_dir tarallo
git clone "$GH_URL"tarallo
cd tarallo || git_error
sed -i 's/image: /image: docker.caste.dev\//g' docker-compose.yml
make up
make examples
cd ..
xdg-open "$TARALLO_URL"
echo -e "\nT.A.R.A.L.L.O. was successfully installed!\nIt is available at $TARALLO_URL\nYou can shut it down from $PWD/tarallo with: make down\n"

echo -e "\nInstalling WEEEhire-ng...\n"
rm_x_dir weeehire-ng
git clone "$GH_URL"weeehire-ng
cd weeehire-ng || git_error
sqlite3 weeehire.db < database.sql
cp config/config-example.php config/config.php
docker-compose up -d
cd ..
xdg-open "$WEEEHIRE_URL"
echo -e "\nWEEEhire-ng was successfully installed!\nIt is available at $WEEEHIRE_URL\nYou can shut it down from $PWD/weeehire-ng with: make down\n"

echo -e "\nInstalling P.E.R.A.C.O.T.T.A. (Progetto Esteso Raccolta Automatica Configurazioni hardware Organizzate Tramite Tarallo Autonomamente)...\n"
rm_x_dir peracotta
git clone "$GH_URL"peracotta
cd peracotta || git_error
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py --gui
deactivate
cd ..
echo -e "\nP.E.R.A.C.O.T.T.A. was successfully installed!\nYou can run it from $PWD/peracotta with: python main.py --gui\n"

echo -e "\nInstalling P.E.S.T.O. (Progetto di Erase Smart con Taralli Olistici)...\n"
rm_x_dir pesto
git clone "$GH_URL"pesto
cd pesto || git_error
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_client.txt
pip install -r requirements_server.txt
python pinolo.py
deactivate
cd ..
echo -e "\nP.E.S.T.O. successfully installed!\nYou can run it from $PWD/pesto with: python pinolo.py\n"

echo -e "\nInstalling S.A.R.D.I.N.A. (Statistiche Amabili Rendimento Degli Informatici Nell’Anno)...\n"
rm_x_dir sardina
git clone "$GH_URL"sardina
cd sardina || git_error
pip install -r requirements.txt
sed -i 's/dev_mode = False/dev_mode = True/g' config.py
sed -i 's/keep_repos = False/keep_repos = True/g' config.py
# run S.A.R.D.I.N.A. in a new terminal window
xterm python main.py --cloc --commits --sloc --graphs --lang
cd ..
echo -e "\nS.A.R.D.I.N.A. was successfully installed!\nYou can run it from $PWD/sardina with: python main.py --cloc --commits --sloc --graphs --lang\nYou can also run it with: docker run --rm -v \$PWD/output:/sardina/output\n"

