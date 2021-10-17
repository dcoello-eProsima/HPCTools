#!/bin/bash

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function build_image () {
	docker build -t hpc_tools_dev "${WORKDIR}"/Docker/
}

function enter_image () {
	docker run --rm -it --security-opt apparmor=unconfined --user "$UID:$GID" \
			--volume="/etc/group:/etc/group:ro" \
			-e "HOME=/home/$USER" \
			-e "DISPLAY=$DISPLAY" \
			--volume="/tmp/.X11-unix:/tmp/.X11-unix" \
			--volume="/home/$USER:/home/$USER" \
			--volume="/etc/passwd:/etc/passwd:ro" \
			--volume="/etc/shadow:/etc/shadow:ro" \
			--volume="${WORKDIR}:/opt/HPCTools" \
			--network host hpc_tools_dev /bin/bash 
}

function format_code () {
    find . -iname "*.h" -o -iname "*.c" | xargs clang-format -i
}

function build () {
	make
}

function vec_info () {
	gcc -Wall -Wextra -ftree-vectorize -fopt-info-vec-missed -O2 -c vec_dgesv.c
}

function gprof_info () {
	gcc -Wall -Wextra -ftree-vectorize -fopt-info-vec-missed -O0 -pg  vec_dgesv.c -lm -lopenblas -llapacke -o test
	./test 1024
	gprof test
	gcc -Wall -Wextra -ftree-vectorize -fopt-info-vec -O3 -pg  vec_dgesv.c -lm -lopenblas -llapacke -o test
	rm test
}

function clean () {
	make clean
}

function execute_in_container {
	docker run --rm -it --user "$UID:$GID" \
					--volume="/etc/group:/etc/group:ro" \
					-e "HOME=/home/$USER" \
					--volume="/home/$USER:/home/$USER" \
    				--volume="/etc/passwd:/etc/passwd:ro" \
    				--volume="/etc/shadow:/etc/shadow:ro" \
					--volume="${WORKDIR}:/opt/HPCTools" \
					--network host hpc_tools_dev /bin/bash /opt/HPCTools/utils.sh "$@"
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
	build)
		build
		;;
	clean)
		clean
		;;
	vec_info)
		vec_info
		;;
	execute_in_container)
		shift
		execute_in_container "$@"
		;;
	gprof)
		gprof_info
		;;
esac
