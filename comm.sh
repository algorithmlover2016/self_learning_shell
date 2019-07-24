#!/usr/bin/sh
#-*- coding:utf-8 -*-

workPath=$(cd $(dirname $0) && pwd)"/"
searchedFileName="searchedFile"
searchedFilePath=${workPath}"${searchedFileName}"
validDataFileName="validData_$(date -d 'now' '+%Y%m%d%H').txt"
validDataFilePath=${workPath}"${validDataFileName}"
logFilePath=${workPath}"../../dataStatic/"
UPPER_LIMIT="20000"

if [ ! -d ${logFilePath} ];
then
    mkdir -p ${logFilePath}
fi

logFileName=${logFilePath}"log_$(date -d 'now' '+%Y%m%d%H')"

# ll -tr | awk '{if ($7 == 2) { print $9}}'> res
$(find ${workPath}../ -ctime -1 -name log_convert_write* | xargs ls > ${searchedFilePath})
if [ -z ${searchedFilePath} ];
then
    exit
fi
# $(postconf -e "message_size_limit = 20480000" && /etc/init.d/postfix restart)
$(cat ${searchedFilePath} | xargs cat > "${validDataFilePath}")
intDealedTotal=$(wc -l "${validDataFilePath}" |awk '{print $1}')

$(/home/work/rmb_odp/hhvm/bin/hhvm "${workPath}Commentstatistic.php" "--fileName=${validDataFilePath}" > "${logFileName}")

intWriteSuc=$(wc -l "${workPath}Dealed/need/convert_write${validDataFileName}")
# intWriteSuc=$(wc -l "${workPath}Dealed/need/convert_write${validDataFileName}" | awk '{print $1}')

msgEmailText="the total number of comment dealed with is "${intDealedTotal}" \n and written successfully in the last 24 hours is ${intWriteSuc/%\ [a-zA-Z\/]*/} \n"
if [ "${UPPER_LIMIT}" -gt "${intDealedTotal}" ];
# if [ 20000 -gt "${intDealedTotal}" ];
then
    msgEmailText="${msgEmailText} the detailed data is appended in Mail attachment"
    # $(echo -e "${msgEmailText}" | mail -s "comment write success statistic" -a "${intWriteSuc/#[0-9]*\ /}"  gaoxiaoxing@baidu.com)
    $(echo -e "${msgEmailText}" | mail -s "comment write success statistic" -a "${intWriteSuc/#[0-9]*\ /}" -c gaoxiaoxing@baidu.com wucheng02@baidu.com )
else
    msgEmailText="${msgEmailText} if you want the detailed data, please contact gaoxiaoxing@baidu.com before $(date -d 'today 20:00:00') \n"
    msgEmailText="${msgEmailText} the absolute file path is ${intWriteSuc/#[0-9]*\ /}"
    sampleFileName=$(sh ./sample.sh "${intWriteSuc/#[0-9]*\ /}")
    # $(echo -e "${msgEmailText}" | mail -s "comment write success statistic" -a "${sampleFileName}" gaoxiaoxing@baidu.com)
    $(echo -e "${msgEmailText}" | mail -s "comment write success statistic" -a "${sampleFileName}" -c gaoxiaoxing@baidu.com wucheng02@baidu.com )
fi

# $(echo -e "${msgEmailText}" | mail -s "comment write success statistic" -c gaoxiaoxing@baidu.com wucheng02@baidu.com )
# $(echo -e "${msgEmailText}" | mail -s "comment write success statistic" -a "${intWriteSuc/#[0-9]*\ /}" -c gaoxiaoxing@baidu.com wucheng02@baidu.com )
exit
