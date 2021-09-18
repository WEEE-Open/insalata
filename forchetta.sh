#!/bin/bash

set -eu

# import variables and functions
source cucchiaio.sh

read -p "Do you want to tear down and clean up everything in this directory? [y/N] " PROCEED
[[ "$PROCEED" = "y" || "$PROCEED" = "Y" ]] || echo -e "\nAborting...\n" || exit 0

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
	sudo killall xterm
else
	echo -e "Skipping xterm termination...\n"
fi

for DIR in tarallo weeehire-ng peracotta pesto sardina; do
	rm_x_dir $DIR
done

