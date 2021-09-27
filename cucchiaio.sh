#!/bin/bash

set -eu

if [[ ! "$OSTYPE" = "linux"* ]]; then
	echo -e "\nThis script must be run on GNU/Linux. Aborting...\n"
	exit 1
fi

read -p "This script will install all the demo software of team WEEE Open with its necessary dependencies. Do you want to proceed? [y/N] " PROCEED
if ! [[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]]; then
	echo -e "\nAborting...\n"
	exit 0
fi

read -p "Do you have an Internet connection? (OR you have already downloaded everything and you don't want to reinstall anything) [Y/n] " INTERNET
if [[ "$INTERNET" = "n" || "$INTERNET" = "N" ]]; then
	echo -e "\nSkipping reinstallation from scratch, launching everything that is already installed...\n"
	INTERNET=0
else
	echo -e "\nReinstalling everything from scratch...\n"
	INTERNET=1
fi
sleep 2  # to let the user acknowledge their choice

# Arch vs Debian -based detection
[[ -f /etc/debian_version ]] && DISTRO_BASE="debian" || DISTRO_BASE="arch"
[[ $EUID = 0 ]] && SUDO="" || SUDO="sudo"
GH_URL="https://github.com/weee-open/"
DEPS="git make docker.io docker-compose pciutils i2c-tools mesa-utils smartmontools dmidecode python3 python3-pip python3-venv cloc sqlite3 xterm gnupg2 pass wget htop vim"
TARALLO_URL="http://localhost:8080"
WEEEHIRE_URL="http://localhost:8082"

if [[ $INTERNET = 1 ]]; then
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

	echo -e "\nUpdating pip3...\n"
	pip3 install --upgrade pip
fi

if [[ ! "$(groups)" = *"docker"* ]]; then
	# docs here: https://docs.docker.com/engine/install/linux-postinstall/
	# NO: but we want to immediately have access to docker without sudo, so: https://stackoverflow.com/a/63311331
	echo -e "\nEnabling user to run docker without sudo (first time only)...\nPLEASE LOGOUT AND LOG BACK IN, a user cannot be added to a new group inside a script.\n"
	$SUDO usermod -aG docker $USER
	exit 0
	#newgrp docker  # this sets the current group list to ONLY docker, which is wrong
	#$SUDO chgrp docker $(which docker)
	#$SUDO chmod g+s $(which docker)
fi

if [[ $INTERNET = 1 ]]; then
	echo -e "\nLogin into our docker registry (first time only)...\n"
	docker login docker.caste.dev
fi

function _git_error() {
	echo -e "\nThere was an error with git clone, aborting...\n"
	exit 2
}

# remove existing directory
function _rm_x_dir() {
	[[ -d "$1" ]] && $SUDO rm -rf "$1" || true  # true needed to keep running if dir does not exist
}

function setup_cd_dir() {
	if [[ $INTERNET = 1 ]]; then
		_rm_x_dir "$1"
		git clone "$GH_URL$1"
		cd "$1" || _git_error
		return 0
	else
		cd "$1" &> /dev/null || return 1
		return 0
	fi
}

function make_venv() {
	[[ ! -d venv ]] && python3 -m venv venv
	source venv/bin/activate
}

# these packages need to be up-to-date before installing Python dependencies
function prep_venv() {
	pip install setuptools wheel
	pip install --upgrade pip setuptools wheel
}

echo -e "\nInstalling T.A.R.A.L.L.O (Tuttofare Assistente il Riuso di Aggeggi Logori e Localmente Opprimenti)...\n"
if setup_cd_dir tarallo; then
	#sed -i 's/image: /image: docker.caste.dev\//g' docker-compose.yml
	make up
	cd ..
	xdg-open "$TARALLO_URL"
	echo -e "\nT.A.R.A.L.L.O. was successfully installed!\nIt is available at $TARALLO_URL\nYou can shut it down from $PWD/tarallo with: make down\n"
else
	echo -e "\nT.A.R.A.L.L.O. could not start.\nYou should try reinstalling it from scratch.\nContinuing...\n"
	sleep 2
fi

echo -e "\nInstalling WEEEhire-ng...\n"
if setup_cd_dir weeehire-ng; then
	[[ ! -f weeehire.db ]] && sqlite3 weeehire.db < database.sql
	[[ ! -f config/config.php ]] && cp config/config-example.php config/config.php
	docker-compose up -d
	cd ..
	xdg-open "$WEEEHIRE_URL"
	echo -e "\nWEEEhire-ng was successfully installed!\nIt is available at $WEEEHIRE_URL\nYou can shut it down from $PWD/weeehire-ng with: docker-compose down\n"
else
	echo -e "\nWEEEhire-ng could not start.\nYou should try reinstalling it from scratch.\nContinuing...\n"
	sleep 2
fi

echo -e "\nInstalling P.E.R.A.C.O.T.T.A. (Progetto Esteso Raccolta Automatica Configurazioni hardware Organizzate Tramite Tarallo Autonomamente)...\n"
if setup_cd_dir peracotta; then
	make_venv
	[[ $INTERNET = 1 ]] && prep_venv
	[[ $INTERNET = 1 ]] && pip install -r requirements.txt
	[[ ! -f .env ]] && cp .env.example .env
	xterm -hold -title "P.E.R.A.C.O.T.T.A." -e "python main.py --gui; bash" &
	#deactivate
	cd ..
	echo -e "\nP.E.R.A.C.O.T.T.A. was successfully installed!\nYou can run it from $PWD/peracotta in the new xterm window with: python main.py --gui\n"
else
	echo -e "\nP.E.R.A.C.O.T.T.A. could not start.\nYou should try reinstalling it from scratch.\nContinuing...\n"
	sleep 2
fi

echo -e "\nInstalling P.E.S.T.O. (Progetto di Erase Smart con Taralli Olistici)...\n"
if setup_cd_dir pesto; then
	make_venv
	[[ $INTERNET = 1 ]] && prep_venv
	[[ $INTERNET = 1 ]] && pip install -r requirements_client.txt
	[[ $INTERNET = 1 ]] && pip install -r requirements_server.txt
	xterm -hold -title "P.E.S.T.O. Server" -e "python basilico.py; bash" &
	sleep 5
	xterm -hold -title "P.E.S.T.O. Client" -e "python pinolo.py; bash" &
	#deactivate
	cd ..
	echo -e "\nP.E.S.T.O. successfully installed!\nYou can run it from $PWD/pesto with: python pinolo.py\n"
else
	echo -e "\nP.E.S.T.O. could not start.\nYou should try reinstalling it from scratch.\nContinuing...\n"
	sleep 2
fi

echo -e "\nInstalling S.A.R.D.I.N.A. (Statistiche Amabili Rendimento Degli Informatici Nell’Anno)...\n"
if setup_cd_dir sardina; then
	make_venv
	[[ $INTERNET = 1 ]] && prep_venv
	[[ $INTERNET = 1 ]] && pip install -r requirements.txt
	# the docker container uses a different config.py with the needed PAT, these changes could be useful if run without docker
	sed -i 's/dev_mode = False/dev_mode = True/g' config.py || true
	sed -i 's/keep_repos = False/keep_repos = True/g' config.py || true
	xterm -hold -title "S.A.R.D.I.N.A." -e "docker run --rm -v \$PWD/output:/sardina/output -it docker.caste.dev/sardina; while :; do if sudo chown -R \$USER .; then xdg-open output; bash; fi; done" &
	#deactivate
	cd ..
	echo -e "\nS.A.R.D.I.N.A. was successfully installed!\nYou can run it from $PWD/sardina with: docker run --rm -v \$PWD/output:/sardina/output -it docker.caste.dev/sardina\nYou can also run it with: python main.py --cloc --commits --sloc --graphs --lang\n"
else
	echo -e "\nP.E.S.T.O. could not start.\nYou should try reinstalling it from scratch.\nContinuing...\n"
	sleep 2
fi

if [[ $INTERNET = 1 ]]; then
	echo -e "\nOpening WEEE Open's GitHub page in the browser...\n"
	xdg-open "$GH_URL"
	echo -e "\nOpening S.A.R.D.I.N.A. GitHub page in the browser...\n"
	xdg-open "$GH_URL"sardina
fi

