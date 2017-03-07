

# Xenserver Backup Script Plus                    

Based in VM Backup Script by Andy Burton (	http://www.andy-burton.co.uk/blog/ - andy@andy-burton.co.uk )                         

Criated: 07/07/2015 
                  
Autor: Rogerio da Costa Dantas Luiz @rogeriocdluiz -  rogeriocdluiz@gmail.com           
                                                              
                                                             
References:                              
                     
                     
http://run.tournament.org.il/category/disk-storage/     
http://forums.citrix.com/message.jspa?messageID=1342058   
					



## Script para backup de máquinas virtuais no Xenserver

Rotina de backup é realizada utilizando snapshots da vm para que cópia seja feita sem downtime e com salvamento em servidor NFS ou em diretório local (versão mais recente)


Para execução do backup basta incluir a linha abaixo no crontab do servidor Xenserver (ou o master do pool) do qual deseja que seja feito o backup das VMs.


0 0 * * 6 /diretoriodoscript/start_backup.sh

Esta linha fará com que o script seja executado todos os sábados à zero hora. 

Script realiza o backup em um diretório compartilhado em um servidor NFS ou diretório local.


Para o envio de emais é necessário editar o arquivo /etc/ssmtp/ssmtp.conf e alterar a linha mailhub para que aponte para o servidor de email correto.


----------------------------------------------------------------------------------------------------------------------------------------

## Arquivo de configuração


O arquivo vm_backup.cfg contém confgiurações gerais para realização do backup. Faça as alterações de acordo com sua necessidade.


### Nome do servidor
server name
SERVER=`uname -n` 


### Diretório local para montagem de servidor NFS
Local backup directory
The script will mount the NFS server volume in this place

backup_dir="/mnt/backup"



### Email para envio notificações
email to send notification
EMAIL=fulano@blabla.com


### Número máximo de dias para guarda de arquivos de backup 
nember of days to keep backups
DAYS=8

### Utilização de espaço máxima para se realizar backup
space limit in NFS Server to make backup
THRESHOLD=80


### Remetente de email
email sender

EMAIL_SERVER=$SERVER@dominio.com


### Tipo de backup
Pode ser "NFS" - Para backup em servidor NFS remoto ou "Local" para cópia no sistema de arquivos local.

BACKUP_TYPE="NFS"





### Diretório compartilhado no servidor NFS
remote NFS server dir

VOLUME_NFS="/bkp/bkpvm/lab"   


### Servidor NFS
NFS server name or IP

NFS_SERVER="endereco_do_servidor_ou_ip"  


### arquivo de log
Set log path
log_path="$backup_dir/vm_backup.log.tmp"


Enable logging
Remove to disable logging

log_enable



### Extensão do arquivo de backup
Backup extension
.xva is the default Citrix template/vm extension

backup_ext=".xva"

### Modalidade de backup
Which VMs to backup. Possible values are:
* "all" - Backup all VMs
* "running" - Backup all running VMs
* "running-so" - Backup only system disc of running VMs
* "list" - Backup all VMs in the backup list (see below)
* "none" - Don't backup any VMs, this is the default

backup_vms="running-so"


VM backup list
Only VMs in this list will be backed up when backup_ext="list"
You can add VMs to the list using: add_to_backup_list "uuid"

Example:
add_to_backup_list "2844954f-966d-3ff4-250b-638249b66313"


### Data
Current Date
This is appended to the backup file name and the format can be changed here
Default format: YYYY-MM-DD_HH-MM-SS

date=$(date +%d-%m-%Y_%H-%M-%S)
