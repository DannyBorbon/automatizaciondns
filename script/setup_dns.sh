#!/bin/bash
# Script de instalación y configuración DNS para reprobados.com

# --- Verificar si bind9 está instalado ---
if ! dpkg -l | grep -qw bind9; then
    echo "Instalando BIND9..."
    sudo apt update
    sudo apt install -y bind9 bind9utils bind9-doc
else
    echo "BIND9 ya está instalado."
fi

# --- Solicitar IPs al usuario ---
read -p "Ingrese IP de la máquina servidor DNS: " SERVER_IP
read -p "Ingrese IP de la máquina cliente (a la que apuntará DNS): " CLIENT_IP

# --- Configuración de zona DNS ---
ZONE_FILE="/etc/bind/db.reprobados.com"
CONF_FILE="/etc/bind/named.conf.local"

# Crear archivo de zona si no existe
if [ ! -f "$ZONE_FILE" ]; then
cat <<EOF | sudo tee $ZONE_FILE
\$TTL    604800
@       IN      SOA     dns.reprobados.com. root.reprobados.com. (
                            1         ; Serial
                            604800    ; Refresh
                            86400     ; Retry
                            2419200   ; Expire
                            604800 )  ; Negative Cache TTL
;
@       IN      NS      dns.reprobados.com.
@       IN      A       $CLIENT_IP
www     IN      A       $CLIENT_IP
EOF
echo "Archivo de zona $ZONE_FILE creado."
else
# Mensaje si ya existe el archivo de zona
    echo "Archivo de zona $ZONE_FILE ya existe. No se sobrescribirá."
fi

# Configurar named.conf.local
if ! grep -q "reprobados.com" $CONF_FILE; then
cat <<EOF | sudo tee -a $CONF_FILE
zone "reprobados.com" {
    type master;
    file "$ZONE_FILE";
};
EOF
echo "Zona reprobados.com agregada a $CONF_FILE"
else
# Mensaje en caso de ya cuenta con la zona ya configurada
    echo "Zona ya configurada en $CONF_FILE"
fi

# --- Verificar configuración y reiniciar servicio ---
sudo named-checkconf
sudo systemctl restart bind9
echo "Configuración de DNS completada de forma correcta."