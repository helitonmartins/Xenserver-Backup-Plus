#!/bin/bash


################################################################
#                                                              #
#              Xenserver Backup Script Plus                    #
#                                                              #
#             Script para backup apenas de matadados           #
#                                                              #
#                                                              #
################################################################



# Definindo diretório atual
dir=`dirname $0`

# Carregando configurações e funcões
. $dir"/vm_backup.lib"
. $dir"/vm_backup.cfg"



#Monta NFS
umount $backup_dir


mount -t nfs $NFS_SERVER:$VOLUME_NFS $backup_dir



#checa se volume realmente está montado
if mount|grep $backup_dir > /dev/null; then

		rm -f $backup_dir/$SERVER.bak
		rm -f $backup_dir/$SERVER-metadata.bak

		#Backup do host
		xe host-backup file-name=$backup_dir/$SERVER.bak host=$SERVER

		#Backup do Pool
		xe pool-dump-database file-name=$backup_dir/$SERVER-metadata.bak


		rm -f $directory/message.tmp
		cat $directory/mailheader.txt > $directory/message.tmp
		echo "Subject: Backup de Metadados realizado - $SERVER" >> $directory/message.tmp
		echo "====================================================" >> $directory/message.tmp
		echo "I made host and pool backup" >> $directory/message.tmp
		ls $backup_dir/*.bak >> $directory/message.tmp
		/usr/sbin/ssmtp $EMAIL < $directory/message.tmp
		
else

	rm -f $directory/message.tmp
	cat $directory/mailheader.txt > $directory/message.tmp
	echo "Subject: Xenserver - $SERVER - Rotina de backup não realizada" >> $directory/message.tmp
	echo "=============================================================" >> $directory/message.tmp
	echo ""
	echo "Volume de Backup não foi montado" >> $directory/message.tmp
	/usr/sbin/ssmtp $EMAIL < $directory/message.tmp
	
	umount $VOLUME


fi


exit 0

