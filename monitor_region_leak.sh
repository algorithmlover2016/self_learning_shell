#!/bin/sh
#-*-coding:utf-8-*-
# the command to execute leak statistic
alias bmrctl="/home/bmrctl/.jumbo/bin/bmrctl"
# work_dir
work_root=$(cd $(dirname $0); pwd)
# data_dir
data_dir="data"
data_dir_path="${work_root}/${data_dir}"
if [ ! -d "${data_dir_path}" ]
then
    mkdir -p "${data_dir_path}"
fi
# rm the history files that is modified before seven days
# $(find "${data_dir_path}" -type f -name "leak_*.txt" -mtime -7 -exec rm -rf {}\;)
$(find "${data_dir_path}" -type f -name "leak_*" -mtime +7 -exec rm -rf {} \;)

monitor_time=$(date +"%Y%m%d_%H%M%S")
monitor_file_name="leak_${monitor_time}"
regions=("bj" "bdbl" "hbfsg" "sz" "sh" "gz" "hk" "rd" "qa")
all_region_file="${data_dir_path}/${monitor_file_name}_allregion.txt"
all_region_file_format="${data_dir_path}/${monitor_file_name}_allregion_ids.txt"
:>"${all_region_file}"
append_file_name="${data_dir_path}/leak_region_${monitor_time}.tar.gz"
rm -rf "${append_file_name}"
append_files="${all_region_file}"
total_num=0
# according to regions loop the requests
for region in ${regions[@]}
do
    echo "check $region begin"
    echo "---------------$region begin---------------" >> "${all_region_file}"
    echo -e "instance_id\t\tuser_token\t\tregion_zone" > "${data_dir_path}/${monitor_file_name}_${region}.txt"
    # get the possible leaking vms list
    bmrctl cluster --region="$region" leak >> "${data_dir_path}/${monitor_file_name}_${region}.txt"
    # touch "${data_dir_path}/${monitor_file_name}_${region}.txt"
    # statistic the number of the possible leaking vms
    region_num=$(cat "${data_dir_path}/${monitor_file_name}_${region}.txt" | grep -v "instance_id" \
                 |wc -l | awk '{print $1}')
    # statistic the total number in all the region
    let total_num+=$region_num

    cat "${data_dir_path}/${monitor_file_name}_${region}.txt" >> "${all_region_file}"
    echo "total $region_num virtual machines maybe leak" >> "${data_dir_path}/${monitor_file_name}_${region}.txt"
    echo "---------------$region done---------------" >> "${all_region_file}"
    echo "check $region done"
    # the files that leaking vms in each region 
    append_files="${append_files} ${data_dir_path}/${monitor_file_name}_${region}.txt"
done
echo "total $total_num vms maybe leak" >> "${all_region_file}"
# reformat the vms list, only instance_id user_token avaliability_zone
cat "${all_region_file}" | grep -v "\-\-\-\-\-\-" | grep -v 'instance_id' \
 | grep -v "vms maybe leak" >  "${all_region_file_format}"
# package all the files
tar zcfP "${append_file_name}" ${append_files}
#sendmail
mail -s "vms leak" -a "${append_file_name//${work_root}/.}" \
     -a ${all_region_file_format//${work_root}/.} "gaoxiaoxing@baidu.com" -c "wudi13@baidu.com" < "${all_region_file}"
# because the function of sendmail in in build02 doesn't work well, copy appendding files to other machine and resendmails
scp "${append_file_name//${work_root}/.}" "${all_region_file_format//${work_root}/.}" \
    "${all_region_file//${work_root}/.}" "gaoxiaoxing@yq01-dhp-solaria0005.yq01.baidu.com:/home/users/gaoxiaoxing/gaoxiaoxing/data/"
ssh root@yq01-dhp-solaria0005.yq01.baidu.com "cd /home/users/gaoxiaoxing/gaoxiaoxing/; find \"./data/\" -type f -name \"leak_*\" -mtime +7 -exec rm -rf {} \; ; mail -s \"BMR virtual machines list\" -a \"${append_file_name//${work_root}/.}\" \
 -a ${all_region_file_format//${work_root}/.} \"gaoxiaoxing@baidu.com\" -c \"wudi13@baidu.com\" < \"${all_region_file//${work_root}/.}\""
