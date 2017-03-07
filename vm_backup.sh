#!/bin/bash


################################################################
#                                                              #
#              Xenserver Backup Script Plus                    #
#                                                              #
#             Based in VM Backup Script by                     #
#                                                              #
#                     Andy Burton                              #
#	http://www.andy-burton.co.uk/blog/                     #
# 		andy@andy-burton.co.uk                         #
#                                                              #
#                  Criated: 07/07/2015                         #
#                                                              #
#                      Version 1.0                             #
#                                                              #
#                        pt-BR                                 #
#                                                              #
#                   Script de backup                           #
#                                                              #
#    Autor: Rogerio da Costa Dantas Luiz @rogeriocdluiz        # 
#                                                              #
#                rogeriocdluiz@gmail.com                       #
#                                                              #
#                                                              #
#                     References:                              #
#      http://run.tournament.org.il/category/disk-storage/     #
#    http://forums.citrix.com/message.jspa?messageID=1342058   #
#							       #
#                                                              #
################################################################



#inserir linha no crontab para execução às 0h do sábado, todos os sábados. desde que caia entre o dia 20 e o dia 26
#0 0 * * 6 DIRETORIO_DOS_SCRIPTS/vm_backup.sh


# Definindo diretório atual
dir=`dirname $0`

# Carregando configurações e funcões
. $dir"/vm_backup.lib"
. $dir"/vm_backup.cfg"



#retorna uuid do master do Pool
POOL_MASTER=`xe pool-list | grep master | /bin/awk '{ print $NF}'`

#retorna o nome do host de acordo co o uuid
POOLMASTER_NAME=`xe host-param-get param-name=name-label uuid=$POOL_MASTER`

#Checa se host atual é o master do Pool
if [ $SERVER != $POOLMASTER_NAME ]; then
	echo "Host atual nao e o master do Pool....Saindo"
	exit 0
fi




#definindo tipo do backup
if [ $BACKUP_TYPE == "NFS" ]; then

	#Monta NFS
	umount $backup_dir

	mount -t nfs $NFS_SERVER:$VOLUME_NFS $backup_dir


elif [ $BACKUP_TYPE = "Local" ]; then

	echo "fazendo backup localmente"


else

	echo "opcao invalida.....saindo"
	exit 0

fi




echo "To: $EMAIL" > $directory/mailheader.txt
echo "From: $EMAIL_SERVER" >> $directory/mailheader.txt




#checa se volume realmente está montado
if mount|grep $backup_dir > /dev/null; then

	#checa espaco do volume montado
	#se for usado apenas nome completo do servidor (com dominio) ao invez do primeiro nome ou ip trocar $4 em {print $4} por $5.
	CURRENT=$(df $backup_dir | grep $backup_dir | awk '{ print $4}' | sed 's/%//g')

	if [ "$CURRENT" -gt "$THRESHOLD" ] ; then

		rm -f $directory/message.tmp
		cat $directory/mailheader.txt > $directory/message.tmp
		echo "Subject: Xenserver - $SERVER - Rotina de backup não realizada" >> $directory/message.tmp
        echo "=============================================================" >> $directory/message.tmp
        echo ""
		echo "Backup não realizado pois espaço livre é insuficiente - Total disponivel na partição de backup é $CURRENT%" >> $directory/message.tmp
		/usr/sbin/ssmtp  $EMAIL < $directory/message.tmp
		
		umount $backup_dir
		
		

		exit 0
		
	else

		#Apaga log antigo
		rm -rf $log_path
		

		# Apaga arquivos de backup mais antigos gerados a mais de DAYS dias atrás além dos logs de execuções anteriores
		find $backup_dir/*.xva -type f -mtime +$DAYS | xargs rm -rf
		find $backup_dir/*.log.* -type f -mtime +7 | xargs rm -rf


		rm -f $directory/message.tmp
		cat $directory/mailheader.txt > $directory/message.tmp
		echo "Subject: Xenserver $SERVER - Cleaned Backup Drive" >> $directory/message.tmp
		echo "====================================================" >> $directory/message.tmp
		echo "I cleaned up the backup drive" >> $directory/message.tmp

		echo "" >> $directory/message.tmp
		ls $backup_dir >> $directory/message.tmp
		echo "====================================================" >> $directory/message.tmp
		echo "" >> $directory/message.tmp
		df -h >> $directory/message.tmp
		/usr/sbin/ssmtp  $EMAIL < $directory/message.tmp



		#Realizando backups dohost e do pool
		if [ $vm_log_enabled ]; then
			log_message "Backup Meta-data and Host-data"
		fi

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





		case $backup_vms in
			
			"all")
				if [ $vm_log_enabled ]; then
					log_message "Backup All VMs"
				fi
				set_all_vms
				backup_vm_list
				;;	
				
			"running")
				if [ $vm_log_enabled ]; then
					log_message "Backup running VMs"
				fi
				set_running_vms
				backup_vm_list
				;;


			"running-so")
				if [ $vm_log_enabled ]; then
					log_message "Backup running VMs"
				fi
				set_running_vms_so
				backup_vm_list_so
				;;


				
			"list")
				if [ $vm_log_enabled ]; then
					log_message "Backup list VMs"
				fi
				backup_vm_list
				;;
				
			*)
				if [ $vm_log_enabled ]; then
					log_message "Backup no VMs"
				fi
				reset_backup_list
				;;
			
		esac

		#Consolida log do backup atual com registros anteriores
		cat $log_path >> $backup_dir/vm_backup.log
		gzip -c $backup_dir/vm_backup.log > $backup_dir/vm_backup.log.`date +%d%m%Y-%H%M%S`.gz
		rm -rf $backup_dir/vm_backup.log



		#Envia informações da execução do backup atual por email
		rm -f $directory/message.tmp
		cat $directory/mailheader.txt > $directory/message.tmp
		FALHAS=`cat $directory/errors.txt`
		echo "Subject: Xenserver - $SERVER - Resultado do Backup - $FALHAS falhas(s)" >> $directory/message.tmp
	    echo "=============================================================" >> $directory/message.tmp
	    echo ""
		echo "Resumo do backup de backup das VMs do servidor Xenserver - $SERVER" >> $directory/message.tmp
		cat $backup_dir/vm_backup.log.tmp >> $directory/message.tmp
		/usr/sbin/ssmtp $EMAIL < $directory/message.tmp

	fi





	if [ $vm_log_enabled ]; then
		log_disable
	fi

	
	if [ $BACKUP_TYPE == "NFS" ]; then

		umount $backup_dir

	elif [ $BACKUP_TYPE = "Local" ]; then

		echo "backup finalizado"

	fi

	# End



else

	rm -f $directory/message.tmp
	cat $directory/mailheader.txt > $directory/message.tmp
	echo "Subject: Xenserver - $SERVER - Rotina de backup não realizada" >> $directory/message.tmp
	echo "=============================================================" >> $directory/message.tmp
	echo ""
	echo "Volume de Backup não foi montado" >> $directory/message.tmp
	/usr/sbin/ssmtp $EMAIL < $directory/message.tmp


	if [ $BACKUP_TYPE == "NFS" ]; then

		umount $backup_dir

	elif [ $BACKUP_TYPE = "Local" ]; then

		echo "backup finalizado"

	fi


fi

exit 0


