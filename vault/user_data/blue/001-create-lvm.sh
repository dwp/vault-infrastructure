#!/bin/bash
echo "Set the Hostname"
hostnamectl set-hostname ${node_name}-${seq_number}


groupadd -g ${consul_group_id} ${consul_group_name}
groupadd -g ${vault_group_id} ${vault_group_name}

useradd -g ${consul_group_id} -u ${consul_user_id} -G ${vault_group_name} -d /home/${consul_user_name} ${consul_user_name}
useradd -g ${vault_group_id} -u ${vault_user_id} -G ${consul_group_name} -d /home/${vault_user_name} ${vault_user_name}

mkdir /home/${consul_user_name}
mkdir /home/${vault_user_name}
chown ${consul_user_name}:${consul_group_name} /home/${consul_user_name}
chown ${vault_user_name}:${vault_group_name} /home/${vault_user_name}
chmod 755 /home/${consul_user_name}
chmod 755 /home/${vault_user_name}


echo "Create the VG and PV required for mounting"
volume_names="${vault_volume_names}"
no_of_volumes_per_vg="${no_of_volumes_per_vg}"
vg_names="${vg_names}"
lv_names="${lv_names}"
no_of_lvs_per_vg="${no_of_lvs_per_vg}"
lv_frees="${lv_frees}"
mount_points="${mount_points}"
bash_volume_names=`echo $volume_names | tr -d '[' | tr -d ']' | tr ',' ' '`
decoded_no_of_volumes_per_vg=`echo $no_of_volumes_per_vg | tr -d '[' | tr -d ']' | tr ',' ' '`
decoded_vg_names=`echo $vg_names | tr -d '[' | tr -d ']' | tr ',' ' '`
decoded_lv_names=`echo $lv_names | tr -d '[' | tr -d ']' | tr ',' ' '`
decoded_mount_points=`echo $mount_points | tr -d '[' | tr -d ']' | tr ',' ' '`
decoded_no_of_lvs_per_vg=`echo $no_of_lvs_per_vg | tr -d '[' | tr -d ']' | tr ',' ' '`
decoded_lv_frees=`echo $lv_frees | tr -d '[' | tr -d ']' | tr ',' ' '`
echo "INFO: Checking if volumes are attached... Atleast 10 times with 3 secs sleep"
check_count=10
while [[ $check_count -gt 0 ]];
do
  for j in $bash_volume_names
  do
    fdisk -l | grep $j
    if [[ $? -ne 0 ]]; then
      found="no"
      break
    else
      found="yes"
    fi
  done
  if [[ $found = "no" ]]; then
   sleep 3
   check_count=`expr $check_count - 1`
  else
    break
  fi
done
if [[ $found = "no" ]]; then
  echo "Disk is still not attached. Cant proceed"
  exit 1
fi
echo "INFO: Creating Volumes"
for i in $bash_volume_names
do
  pvcreate $i
done
count=0
cut_number=0
for i in $decoded_vg_names
do
  echo "INFO: Creating $i volume group"
  cut_number=`expr $cut_number + 1`
  no_of_volumes=`echo $decoded_no_of_volumes_per_vg | cut -d " " -f $cut_number`
  if [[ $count -eq 0 ]]; then
    volumes_min_count=`expr $count + 1`
    volumes_max_count=`expr $count + $no_of_volumes`
  else
    volumes_min_count=`expr $volumes_max_count + 1`
    volumes_max_count=`expr $volumes_max_count + $no_of_volumes`
  fi
  if [[ $volumes_min_count -eq $volumes_max_count ]]; then
    volume_names_per_vg=`echo $bash_volume_names | cut -d " " -f $volumes_min_count`
  else
    volume_names_per_vg=`echo $bash_volume_names | cut -d " " -f $volumes_min_count-$volumes_max_count`
  fi
  echo "INFO: Creating $i volume group"
  vgcreate $i $volume_names_per_vg
  no_of_lvs=`echo $decoded_no_of_lvs_per_vg | cut -d " " -f $cut_number`
  if [[ $count -eq 0 ]]; then
    lv_min_count=`expr $count + 1`
    lv_max_count=`expr $count + $no_of_lvs`
  else
    lv_min_count=`expr $lv_max_count + 1`
    lv_max_count=`expr $lv_max_count + $no_of_lvs`
  fi
  if [[ $lv_min_count -eq $lv_max_count ]]; then
    lv_names_per_vg=`echo $decoded_lv_names | cut -d " " -f $lv_min_count`
    lv_frees_per_vg=`echo $decoded_lv_frees | cut -d " " -f $lv_min_count`
    mounts_per_vg=`echo $decoded_mount_points | cut -d " " -f $lv_min_count`
  else
    lv_names_per_vg=`echo $decoded_lv_names | cut -d " " -f $lv_min_count-$lv_max_count`
    lv_frees_per_vg=`echo $decoded_lv_frees | cut -d " " -f $lv_min_count-$lv_max_count`
    mounts_per_vg=`echo $decoded_mount_points | cut -d " " -f $lv_min_count-$lv_max_count`
  fi
  lv_count=1
  for lv in $lv_names_per_vg
  do
    free=`echo $lv_frees_per_vg | cut -d " " -f $lv_count`
    mount=`echo $mounts_per_vg | cut -d " " -f $lv_count`
    echo "INFO: Creating LV $lv for $i volume group"
    lvcreate --name $lv -l $free%FREE $i
    echo "INFO: Creating the FS for $lv"
    mkfs.xfs /dev/$i/$lv
    mkdir -p $mount
    mount /dev/$i/$lv $mount
    echo "/dev/$i/$lv $mount xfs defaults 1 2" >> /etc/fstab
    lv_count=`expr $lv_count + 1`
  done
  count=`expr $count + 1`
done
#For consul agent
mkdir -p ${consul_data_path}
mkdir -p ${consul_ssl_path}
mkdir -p ${consul_config_path}
#For Vault Server
mkdir -p ${vault_log_path}
mkdir -p ${vault_config_path}
mkdir -p ${vault_ssl_path}
mkdir -p ${vault_data_path}
mkdir -p ${vault_plugin_path}

for i in $decoded_mount_points
do
  if [[ $i = "/consul" ]]; then
    chown -R ${consul_user_name}:${consul_group_name} $i
  else
    chown -R ${vault_user_name}:${vault_group_name} $i
  fi
done
