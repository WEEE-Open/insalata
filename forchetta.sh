#!/bin/bash

set -eu

[[ $EUID = 0 ]] && SUDO="" || SUDO="sudo"

# remove existing directory
function rm_x_dir() {
	[[ -d "$1" ]] && $SUDO rm -rf "$1" || true  # true needed to keep running if dir does not exist
}

read -p "Do you want to tear down and clean up everything in this directory? [y/N] " PROCEED
if ! [[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]];then 
	echo -e "\nAborting...\n"
	exit 0
fi

if [[ -d tarallo ]]; then
	cd tarallo
	if [[ -f Makefile ]]; then
		make down
		make destroy
	fi
	cd ..
fi

if [[ -d weeehire-ng ]]; then
	if [[ -f docker-compose.yml ]]; then
		docker-compose down
	fi
fi

read -p "Terminate all xterm processes? [y/N] " PROCEED
if [[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]]; then
	echo -e "Terminating all xterm processes...\n"
	sudo killall xterm &> /dev/null || true
else
	echo -e "Skipping xterm termination...\n"
fi

read -p "Clean up all repo directories? [y/N] " CLEANUP
if [[ "$CLEANUP" = "y" || "$CLEANUP" = "Y" ]]; then
	for DIR in tarallo weeehire-ng peracotta pesto sardina; do
		echo -e "Removing $DIR directory..."
		rm_x_dir $DIR
	done
fi

echo -e "\nTeardown complete!\n"

