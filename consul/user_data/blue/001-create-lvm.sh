#!/bin/bash
echo "Set the Hostname"
hostnamectl set-hostname ${consul_docker_name}

groupadd -g ${group_id} ${group_name}
useradd -g ${group_id} -u ${user_id} -d /home/${user_name} ${user_name}

mkdir /home/${user_name}
chown ${user_name}:${group_name} /home/${user_name}
chmod 755 /home/${user_name}

echo "Create the VG and PV required for mounting"

volume_names="${consul_volume_name}"
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


mkdir -p ${data_path}
mkdir -p ${ssl_path}
mkdir -p ${ca_path}
mkdir -p ${config_path}
mkdir -p ${backup_path}

for i in $decoded_mount_points
do
  chown -R ${user_name}:${group_name} $i
done
