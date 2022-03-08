#!/bin/bash

function startup {
    service="bind9"
    variables=${1-DEFAULT};
    serv="service $service status ";
    $serv  > fuckshit.txt ;
    stat="grep dead fuckshit.txt";
    $stat;
    match="grep --only-matching dead fuckshit.txt";
   
    if [[ "$match"=="true" ]]
    then
        service $service start
        sleep 1
        service $service status
    fi;

}

startup

function backup{
    cp -R /etc/bind /etc/restore-bind;
}


backup


function make_configs{

    file_records="/etc/bind/db.records"
    file_zones="/etc/bind/named.conf.local"
    file_security/"/etc/bind/named.conf.options"


    
    read -p "what is your host name" primary_host_name;
    read -p "what is your domain" domain_name;
    read -p "what is your IP ADDR" local_ip;
    read -p "what is secondary host name" secondary_host_name;
    read -p "what is secondary IP ADDR" secondary_ip;
    read -p "what is mail host name" mail_host_name;
    read -p "what is mail IP ADDR" mail_ip;
    revip=$(printf "$local_ip" | awk -F '.' '{print $3,$2,$1}' OFS='.');



    echo"$TTL 3600

@	IN 	SOA	 $primary_host_name.$domain_name.local. secondaryHostName.$domain_name.local. (
			1		; Serial
			604800	; Refresh 
			86400		; Retry
			2419200	; Expire
			604800 )	; Negative Cache TTL

@	IN 	NS	$primary_host_name.$domain_name.local.
@	IN 	NS	$Secondary_host_name.$domain_name.local.
@	IN 	MX	10	$mail_host_name.$domain_name.local.
$primary_host_name	IN 	A	$local_ip
$Secondary_host_name	IN	A	$Secondary_ip
$mail_host_name	IN	A	$mail_ip
DNS	IN	CNAME	$primary_host_name
10	IN	PTR	$primary_host_name.$domain_name.local.
20	IN	PTR	$Secondary_host_name.$domain_name.local.
30	IN	PTR	$mail_host_name.$domain_name.local." >> $file_records;




echo "Zone	“$domain_name.local” {
	type master;
	File “/etc/bind/db.records;
	Allow-transfer {“none”;};
};

Zone “$revip.in-addr.arpa” {
	Type master;
File “/etc/bind/db.records”;
allow-transfer{“none”;};
};

Logging {
	Channel query.log {
	File “var/lib/bind/query.log” size 40m;
	Severity debug 3;
	};
	Category queries {query.log;};
};
" >> $file_zones;



echo "Acl “allow”	{
	$primary_ip;
    172.0.0.1;
	$secondary_ip;
};

Options	{
Directory “/var/cache/bind”;

Version none;
	Server-id none;
	Empty-zones-enable no;
	Allow-recursion {allow;};
	Allow-query-cache {any;};
	Allow-transfer {none;};
	
	Forwarders {
		$Secondary_ip;
		8.8.8.8;
		8.8.4.4;
};
	Dnssec-enable yes;
	Dnssec-validation auto;
	
	auth-nxdomain no; 	#conform to RFC1035
	Listen-on port 53 {allow;};
	listen -on-v6 no;
};
" >> $file_security;





chown root:bind $file_records;
chown root:bind $file_zones;
chown root:bind $file_security;



}   


make_configs


echo "The configs have been made and default configs have been backed up to /etc/restore_bind";
echo "Checks have not been made look at after configuration in dooms day on what to do";
echo "if everything returns no errors bind needs restart";


exit 0