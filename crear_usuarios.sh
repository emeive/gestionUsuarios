#!/bin/bash

#Para facilitar las pruebas, aseguramos de que esten borrados los usuarios. 
userdel -r alum1
userdel -r alum2
userdel -r alum3
userdel -r alum4
userdel -r alum5

rm -Rf /home/alum1
rm -Rf /home/alum2
rm -Rf /home/alum3
rm -Rf /home/alum4
rm -Rf /home/alum5

#============================================================================


if [[ $# = 0 || ! -f $1 ]]; then
	echo "Se necesita un fichero valido con usuarios"
	exit
fi

uid_alumnos=1100
uid_usuarios=1400
IFS=$'\n' #El separador de campos es el caracter de final de linea


for linea in $(cat $1)
do
	echo -e "\nNUEVA CUENTA: $linea"
	
	#Guardamos todos los datos necesarios en variables
	nombre=`echo $linea | cut -f1 -d:`
	grupo=`echo $linea | cut -f2 -d:`
	grupoSec=`echo $linea | cut -f3 -d:`
	gid=`grep ^$grupo /etc/group | cut -f3 -d:`
	contrasena=`echo $linea | cut -f4 -d:` 
	expiracion=`echo $linea | cut -f5 -d:`
	
	
	# usuarios 1002 // alumnos 1003
	#vamos modificando el UID de los alumnos
	if [[ $gid = 1003 ]]; then
		uid=$uid_alumnos
		uid_alumnos=$((uid_alumnos+1))

	else
		uid=$uid_usuarios
		uid_usuarios=$((uid_usuarios+1))
		
	fi
	
	#Entrada al etc/passwd
	echo -e "$nombre:x:$uid:$gid:usuario $nombre:/home/$nombre:/bin/bash\n"	
	echo "$nombre:x:$uid:$gid:usuario $nombre:/home/$nombre:/bin/bash" >> /etc/passwd	
	#Imprimimos la entrada que acabamos de añaidr para comprobar que este correcta
	echo $(grep ^$nombre /etc/passwd)


	#Entrada al etc/shadow
	echo "$nombre::::::::"
	echo "$nombre::::::::" >> /etc/shadow
	
	#Creamos el directorio de trabajo y cambiamos sus permisos
	mkdir /home/$nombre
	chmod 0700 /home/$nombre
	
	#Copiamos el contenido de /etc/skel en el directorio de trabajo
	ls -laR /etc/skel | more
	cp -r /etc/skel/.[a-zA-Z]* /home/$nombre
	
	#Cambiamos de forma recursiva el propietario y el grupo propietario del directorio de trabajo
	chown -R $nombre:$grupo /home/$nombre
	
	#Establecemos la contraseña
	echo -e "$contrasena\n$contrasena" | passwd $nombre
	
	#fecha de expiración
	chage -E "$expiracion" "$nombre"
	
	#grupo secundario
	usermod -a -G "$grupoSec" "$nombre"
done

#Visualizamos el contenido de etc/groups para ver si los grupos secundarios se han asignado correctamente	
echo -e "\n\n\n\n\n\n"
echo -e "*** Verificamos contenido del etc/group: ***"
echo "==========================================="
echo -e "$(cat /etc/group | tail -n 5)\n"


#Visualizamos las 5 ultimas entradas del etc/shadow para verificar si se ha establecido una contraseña cifrada.
echo -e "\n"
echo -e "*** Verificamos contenido del etc/shadow: ***"
echo "==========================================="
echo -e "$(cat /etc/shadow | tail -n 5)\n"


#Visualizamos las 5 ultimas entradas del etc/passwd
echo -e "\n"
echo -e "*** Verificamos contenido del etc/passwd: ***"
echo "==========================================="
echo -e "$(cat /etc/passwd | tail -n 5)\n"



