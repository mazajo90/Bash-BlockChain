#!/bin/bash

#Colors
green="\e[0:32m\033[1m"
red="\e[0:31m\033[1m"
yellow="\e[0:33m\033[1m"
blue="\e[0;34m\033[1m"


function ctrl_c(){
    echo -e "${red}\n\n[!]Saliendo...${end}"
    rm ut.t* 2>/dev/null
    tput cnorm &&  exit 1
}

trap ctrl_c INT


function helpPanel(){
    echo -e "${green}\n[+]Uso de la herramienta${end} ${yellow}$0${end}"
    for i in $(seq 1 80); do echo -ne "${green} -"; done; echo -ne "${end}"
    echo -e "\n\n\t${green}e) Modo Exploración${end}"
    echo -e "\t\t${yellow}$main_url$un_url${end}\t${green}Lista de transacciones no confirmadas${end}"
    echo -e "\t\t${yellow}$main_url$in_url${end}\t\t\t\t${green}Inspeccionar hash de transacción${end}"
    echo -e "\t\t${yellow}$main_url$ad_url${end}\t\t\t${green}Inspeccionar una transacciones de direcciones${end}"
    echo -e "\n\n\t${green}h) Mostrar panel de ayuda${end}"
}
#Inicio de Tabla
function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}
#Fin de la Tabla

function unconfirmTransactions(){
    echo '' > ut.tmp
    while [ "$(cat ut.tmp | wc -l)" == 1 ]; do
        curl -s "$main_url$un_url" | html2text > ut.tmp
    done

    hashes=$(cat ut.tmp | grep  "Hash" -A 1 | grep -vE "Hash|--|Tiempo")

    echo "Hash_Tiempo_Suma(BTC)_Suma(USD)" > ut.table
    for hash in $hashes; do
	echo "${hash}_$(cat ut.tmp | grep "$hash" -A 6 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 2 | tail -n 1)" >> ut.table
    done
    printTable '_' "$(cat ut.table)"
}

#Variable
main_url="https://www.blockchain.com/es/btc/"
un_url="unconfirmed-transactions"
in_url="tx"
ad_url="address"

parameter_counter=0;


while getopts "e:h:" arg; do
	case $arg in
	   e) explorer="$OPTARG"; let parameter_counter+=1;;
	   h) helpPanel;; 
	esac
done

if [ $parameter_counter -eq 0 ]; then
	helpPanel
else
	if [ $explorer == "unconfirmTransactions" ]; then
		unconfirmTransactions
	fi
fi

#echo -e "\n[+]$main_url$un_url"
#echo -e "\n[+]$main_url$ad_url"
#echo -e "\n[+]$main_url$in_url"
