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
    echo -e "\n\n\t${green}n) Limitar el numero de resultados${end} ${yellow}(Ejemplo: $0 -e nombre de funcion -n 5)${end}"
    echo -e "\n\n\t${green}i) Busqueda por identificador o hash${end} ${yellow}(Ejemplo: $0 -i hash)${end}"
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
    number_tran=$1
    echo '' > ut.tmp
    while [ "$(cat ut.tmp | wc -l)" == 1 ]; do
        curl -s "$main_url$un_url" | html2text > ut.tmp
    done

    hashes=$(cat ut.tmp | grep  "Hash" -A 1 | grep -vE "Hash|--|Time" | head -n $number_tran)

    echo "Hash_Suma(USD)_Suma(BTC)_Tiempo" > ut.table
    for hash in $hashes; do
	echo "${hash}_$(cat ut.tmp | grep "$hash" -A 6 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 2 | tail -n 1)" >> ut.table
    done

    cat ut.table | tr -d '$' | tr '_' ' ' | awk '{print $2}' | grep -v "Suma(USD)" | sed 's/\..*//g' | tr -d ','> money
    
    money=0; cat money | while read money_line; do
	let money+=$money_line
	echo $money > money.tmp
    done
    

    echo -n "Cantidad Total: " > amount.table
    echo "\$$(printf "%'.d\n" $(cat money.tmp))" >> amount.table

    if [ "$(cat ut.table | wc -l)" != "1" ]; then
	echo -ne "${yellow}"
	printTable '_' "$(cat ut.table)"
	echo -ne "${end}"
	echo -ne "${green}"
	printTable '_' "$(cat amount.table)"
	echo -ne "${end}"
    else
	rm ut.t* 2>/dev/null
    fi
    rm ut.* money* amount.table 2>/dev/null
}

function inspectTran(){

    inspect_tran_hash=$1

    echo "Entradas Total_Gastos Total" > total_entradas_gastos.tmp

    while [ "$(cat total_entradas_gastos.tmp | wc -l)" == "1" ]; do
	curl -s "${in_url}${inspect_tran_hash}" | html2text | grep -E "Total Input|Total Output" -A 1 | grep -v -E "Total Input|Total Output" | xargs | tr ' ' '_' | sed 's/_BTC/BTC/g' >> total_entradas_gastos.tmp
    done 
    echo -ne "${green}"
    printTable '_' "$(cat total_entradas_gastos.tmp)"
    echo -ne "${end}"
    rm total_entradas_gastos.tmp 2>/dev/null
    

    echo "Dirección (Entradas)_Valor" > entradas.tmp

    while [ "$(cat entradas.tmp | wc -l)" == "1" ]; do
         curl -s "${in_url}${inspect_tran_hash}" | html2text | grep "Inputs" -A 500 | grep "Outputs" -B 500 | grep "Address"  -A 3 | grep -v -E "Address|Value|\--" | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> entradas.tmp
    done

    echo -ne "${green}"
    printTable '_' "$(cat entradas.tmp)"
    echo -ne "${end}"
    rm entradas.tmp 2>/dev/null

    echo "Dirección (Salidas)_Valor" > salidas.tmp
    
    while [ "$(cat salidas.tmp | wc -l)" == "1" ]; do
	curl -s "${in_url}${inspect_tran_hash}" | html2text | grep "Outputs" -A 500 | grep "You" -B 500 | grep "Address"  -A 3 | grep -v -E "Address|Value|\--" | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> salidas.tmp
    done

    echo -ne "${green}"
    printTable '_' "$(cat salidas.tmp)"
    echo -ne "${end}"
    rm salidas.tmp 2>/dev/null

}

#Variable
main_url="https://www.blockchain.com/btc/"
un_url="unconfirmed-transactions"
in_url="https://www.blockchain.com/btc/tx/"
ad_url="address"

parameter_counter=0;


while getopts "e:n:i:h:" arg; do
	case $arg in
	   e) explorer="$OPTARG"; let parameter_counter+=1;;
	   n) number_tran="$OPTARG"; let parameter_counter+=1;;
	   i) inspect_tran="$OPTARG"; let parameter_counter+=1;;
	   h) helpPanel;; 
	esac
done

if [ $parameter_counter -eq 0 ]; then
	helpPanel
else
	if [ $explorer == "unconfirmTransactions" ]; then
		if [ ! "$number_tran" ]; then
		    number_tran=100
		    unconfirmTransactions $number_tran
		else
		    unconfirmTransactions $number_tran
		fi
	elif [ $explorer == "inspect" ]; then
		inspectTran $inspect_tran
	fi
fi

#echo -e "\n[+]$main_url$un_url"
#echo -e "\n[+]$main_url$ad_url"
#echo -e "\n[+]$main_url$in_url"
