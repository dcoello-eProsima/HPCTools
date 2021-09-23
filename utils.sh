#!/bin/bash

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function build_image () {
	docker build -t hpc_tools_dev "${WORKDIR}"/Docker/
}

function enter_image () {
	docker run --rm -it --security-opt apparmor=unconfined --user "$UID:$GID" \
			--volume="/etc/group:/etc/group:ro" \
			-e "HOME=/home/$USER" \
			--volume="/home/$USER:/home/$USER" \
			--volume="/etc/passwd:/etc/passwd:ro" \
			--volume="/etc/shadow:/etc/shadow:ro" \
			--volume="${WORKDIR}:/opt/HPCTools" \
			--network host hpc_tools_dev /bin/bash 
}

function format_code () {
    find . -iname "*.h" -o -iname "*.c" | xargs clang-format -i
}

case $1 in
	build_image)
		build_image
		;;
	enter)
		enter_image
		;;
	format)
		format_code
		;;
esac
