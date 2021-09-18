#!/bin/bash

set -eu

if [[ ! "$OSTYPE" = "linux"* ]]; then
	echo -e "\nThis script must be run on GNU/Linux. Aborting...\n"
	exit 1
fi

read -p "This script will install all the demo software of team WEEE Open with its necessary dependencies. Do you want to proceed? [y/N] " PROCEED
[[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]] || echo -e "\nAborting...\n" || exit 0

# Arch vs Debian -based detection
[[ -f /etc/debian_version ]] && DISTRO_BASE="debian" || DISTRO_BASE="arch"
[[ $EUID = 0 ]] && SUDO="" || SUDO="sudo"
GH_URL="https://github.com/weee-open/"
DEPS="git make docker.io docker-compose pciutils i2c-tools mesa-utils smartmontools dmidecode python3 python3-venv cloc sqlite3 xterm gnupg2 pass wget"
TARALLO_URL="http://localhost:8080"
WEEEHIRE_URL="http://localhost:80"

echo -e "\nUpdating local repos...\n"
if [[ "$DISTRO_BASE" = "debian" ]]; then 
	$SUDO apt update || true
else
	$SUDO pacman -Syy || true
fi

echo -e "\nInstalling global dependencies...\n"
if [[ "$DISTRO_BASE" = "debian" ]]; then
	$SUDO apt install -y $DEPS
	# fix for libxcb libraries not found when launching P.E.S.T.O. on Debian
	$SUDO apt install -y libxcb-util0-dev libxcb-xinerama0-dev
	if ! $SUDO apt list --installed | grep libxcb-util1; then
		if wget http://ftp.br.debian.org/debian/pool/main/x/xcb-util/libxcb-util1_0.4.0-1+b1_amd64.deb; then
			$SUDO dpkg -i libxcb-util1_0.4.0-1+b1_amd64.deb 
			rm libxcb-util1_0.4.0-1+b1_amd64.deb
		else
			echo -e "\nCould not install libxcb-util1. Let's hope for the best...\n"
		fi
	fi
else
	$SUDO pacman -Sy $DEPS
fi

if [[ ! "$(groups)" = *"docker"* ]]; then
	# docs here: https://docs.docker.com/engine/install/linux-postinstall/
	echo -e "\nEnabling user to run docker without sudo (first time only)...\n"
	# $SUDO groupadd docker || true
	[[ $EUID != 0 ]] && $SUDO usermod -aG docker $USER || true
	newgrp docker &
fi

echo -e "\nLogin into our docker registry (first time only)...\n"
docker login docker.caste.dev

echo -e "\nUpdating pip3...\n"
pip3 install --upgrade pip

function git_error() {
	echo -e "\nThere was an error with git clone, aborting...\n"
	exit 2
}

# remove existing directory
function rm_x_dir() {
	[[ -d "$1" ]] && rm -rf "$1" || true  # true needed to keep running if dir does not exist
}

# these packages need to be up-to-date before installing Python dependencies
function prep_venv() {
	pip install setuptools wheel
	pip install --upgrade pip setuptools wheel
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
echo -e "\nWEEEhire-ng was successfully installed!\nIt is available at $WEEEHIRE_URL\nYou can shut it down from $PWD/weeehire-ng with: docker-compose down\n"

echo -e "\nInstalling P.E.R.A.C.O.T.T.A. (Progetto Esteso Raccolta Automatica Configurazioni hardware Organizzate Tramite Tarallo Autonomamente)...\n"
rm_x_dir peracotta
git clone "$GH_URL"peracotta
cd peracotta || git_error
python3 -m venv venv
source venv/bin/activate
prep_venv
pip install -r requirements.txt
cp .env.example .env
xterm -hold -title "P.E.R.A.C.O.T.T.A." -e "python main.py --gui; bash" &
#deactivate
cd ..
echo -e "\nP.E.R.A.C.O.T.T.A. was successfully installed!\nYou can run it from $PWD/peracotta in the new xterm window with: python main.py --gui\n"

echo -e "\nInstalling P.E.S.T.O. (Progetto di Erase Smart con Taralli Olistici)...\n"
rm_x_dir pesto
git clone "$GH_URL"pesto
cd pesto || git_error
python3 -m venv venv
source venv/bin/activate
prep_venv
pip install -r requirements_client.txt
pip install -r requirements_server.txt
xterm -hold -title "P.E.S.T.O." -e "python pinolo.py; bash" &
#deactivate
cd ..
echo -e "\nP.E.S.T.O. successfully installed!\nYou can run it from $PWD/pesto with: python pinolo.py\n"

echo -e "\nInstalling S.A.R.D.I.N.A. (Statistiche Amabili Rendimento Degli Informatici Nell’Anno)...\n"
rm_x_dir sardina
git clone "$GH_URL"sardina
cd sardina || git_error
prep_venv
pip install -r requirements.txt
# the docker container uses a different config.py with the needed PAT, these changes could be useful if run without docker
sed -i 's/dev_mode = False/dev_mode = True/g' config.py
sed -i 's/keep_repos = False/keep_repos = True/g' config.py
xterm -hold -title "S.A.R.D.I.N.A." -e "docker run --rm -v \$PWD/output:/sardina/output -it docker.caste.dev/sardina; sudo chown -R \$USER .; xdg-open output; bash" &
#deactivate
cd ..
echo -e "\nS.A.R.D.I.N.A. was successfully installed!\nYou can run it from $PWD/sardina with: docker run --rm -v \$PWD/output:/sardina/output -it docker.caste.dev/sardina\nYou can also run it with: python main.py --cloc --commits --sloc --graphs --lang\n"

