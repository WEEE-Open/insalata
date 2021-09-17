#!/bin/bash

set -eu

[[ "$OSTYPE" = "linux"* ]] || echo "This script must be run on GNU/Linux. Aborting..." || exit 1

read -p "This script will install all the demo software of team WEEE Open with its necessary dependencies. Do you want to proceed? [y/N] " PROCEED
[[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]] || echo "Aborting..." || exit 0

# Arch vs Debian -based detection
[[ -f /etc/debian_version ]] && DISTRO_BASE="debian" || DISTRO_BASE="arch"
[[ $EUID = 0 ]] && SUDO="" || SUDO="sudo"
GH_URL="https://github.com/weee-open/"
DEPS="git make docker.io docker-compose pciutils i2c-tools mesa-utils smartmontools dmidecode python3 python3-venv cloc"
TARALLO_URL="http://localhost:80"
WEEEHIRE_URL="http://localhost:8777"

echo "\nUpdating local repos...\n"
if [[ "$DISTRO_BASE" = "debian" ]]; then 
	$SUDO apt update || true
else
	$SUDO pacman -Syy || true
fi

echo "\nInstalling global dependencies...\n"
if [[ "$DISTRO_BASE" = "debian" ]]; then
	$SUDO apt install -y $DEPS
else
	$SUDO pacman -Sy $DEPS
fi

if [[ ! "$(groups)" = *"docker"* ]]; then
	# docs here: https://docs.docker.com/engine/install/linux-postinstall/
	echo "\nEnabling user to run docker without sudo (first time only)...\n"
	$SUDO groupadd docker || true
	[[ $EUID != 0 ]] && $SUDO usermod -aG docker $USER
	newgrp docker
fi

function git_error() {
	echo "There was an error with git clone, aborting..."
	exit 2
}

echo "Installing T.A.R.A.L.L.O (Tuttofare Assistente il Riuso di Aggeggi Logori e Localmente Opprimenti)...\n"
git clone "$GH_URL"tarallo
cd tarallo || git_error
sed -i 's/image: /image: docker.caste.dev\//g' docker-compose.yml
make up
make examples
cd ..
xdg-open "$TARALLO_URL"
echo "T.A.R.A.L.L.O. was successfully installed!\nIt is available at $TARALLO_URL\nYou can shut it down from this directory with: docker-compose down\n"

echo "Installing WEEEhire-ng...\n"
git clone "$GH_URL"weeehire-ng
cd weeehire-ng || git_error
sqlite3 weeehire.db < database.sql
cp config/config-example.php config/config.php
docker-compose up -d
cd ..
xdg-open "$WEEEHIRE_URL"
echo "WEEEhire-ng was successfully installed!\nIt is available at $WEEEHIRE_URL\nYou can shut it down from this directory with: docker-compose down\n"

echo "Installing P.E.R.A.C.O.T.T.A. (Progetto Esteso Raccolta Automatica Configurazioni hardware Organizzate Tramite Tarallo Autonomamente)...\n"
git clone "$GH_URL"peracotta
cd peracotta || git_error
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py --gui
deactivate
cd ..
echo "P.E.R.A.C.O.T.T.A. was successfully installed!\n"

echo "Installing P.E.S.T.O. (Progetto di Erase Smart con Taralli Olistici)...\n"
git clone "$GH_URL"pesto
cd pesto || git_error
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_client.txt
pip install -r requirements_server.txt
python pinolo.py
deactivate
cd ..
echo "P.E.S.T.O. successfully installed!\n"

echo "Installing S.A.R.D.I.N.A. (Statistiche Amabili Rendimento Degli Informatici Nell’Anno)...\n"
git clone "$GH_URL"sardina
cd sardina || git_error
pip install -r requirements.txt
sed -i 's/dev_mode = False/dev_mode = True/g' config.py
sed -i 's/keep_repos = False/keep_repos = True/g' config.py
# run S.A.R.D.I.N.A. in a new terminal window
xterm python main.py --cloc --commits --sloc --graphs --lang
cd ..
echo "S.A.R.D.I.N.A. was successfully installed!\nYou can also run it with: docker run --rm -v $PWD/output:/sardina/output\n"

