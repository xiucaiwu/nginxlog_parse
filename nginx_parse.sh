#!/bin/bash

echo "##########################################################################"
echo "#   nginx日志分析小工具,author:william,https://github.com/xiucaiwu       #"
echo "#   本工具暂时不支持跨天日志分析,Nginx日志格式为默认格式                 #"
echo "#   请输入要分析的时段(为空则分析全部日志):                              #"
echo "#   分析今天3点10分到5点的数据:03:10-05:00 "-"前后没有空格               #"
echo "#   分析2018年8月20号3点到5点的数据:2018-08-20 03:00-05:00               #"
echo "##########################################################################"

# 默认存放切割后的Nginx日志目录
default_parse_ngx_dir_path='/opt/log/nginx'
# 生成的切割后的Nginx日志路径
parse_ngx_path=""
# 默认Nginx日志路径
#default_ngx_path="/usr/local/nginx/logs/host.access.145.`date "+%Y%m%d"`.log"
default_ngx_path="/root/wwwlog/access.log"
# 记录用户手动输入Nginx日志路径的字符串长度
ngx_path_len=0
# 记录用户手动输入切割后的Nginx日志目录字符串长度
ngx_dir_path_len=0
# 一个空数组
array=()
# 一个字符串分割另一个字符串
function str_split(){
	# 分割字符串
	delimiter=$1
	# 目标字符串
	string=$2
	# 注意后面有个空格
	array=(${string//$delimiter/ })
	# return 只能返回int型数值
#	return $arr
}

read -p "请输入nginx日志文件路径:" ngx_path
ngx_path_len=`echo $ngx_path | wc -L`
if [ `echo $ngx_path | wc -L` == 0 ];then
	ngx_path=$default_ngx_path
fi
if [ ! -f $ngx_path ];then
	echo "日志不存在"
#	exit
fi

read -p "请输入存放分析后的nginx日志文件夹路径,默认为/opt/log/nginx:" ngx_parse_dir_path
if [ `echo $ngx_dir_path | wc -L` == 0 ];then
	ngx_parse_dir_path=$default_parse_ngx_dir_path
fi
if [ ! -d $ngx_parse_dir_path ];then
	echo $ngx_parse_dir_path "不存在"
#	exit
fi

read -p "请输入要分析的时段(24小时制):" ngx_time
# 统计输入的字符串长度
len=`echo $ngx_time | wc -L`
if [ $len == 0 ];then
	# 当前是几时几分
	hour_minute=`date +%H:%I`
	filename=`date +%Y%m%d`".log"
	mydate=`date +%d/%b/%Y`
	parse_ngx_path=$ngx_parse_dir_path/$filename
	
	echo -e "\033[32m 文件${parse_ngx_path}正在生成... \033[0m"
	awk -v mydate=$mydate -v arr=$hour_minute -F "[ /:]" '$1"/"$2"/"$3==mydate && $4":"$5>="00:00" && $4":"$5<=arr' $ngx_path > $parse_ngx_path
	echo -e "\033[32m 文件${parse_ngx_path}生成成功!!! \033[0m"
elif [ $len == 11 ];then
	# 统计"-"出现的次数
	if [ `echo $ngx_time | grep -o '-' | wc -l` == 1 ];then
		# 当前日期
		current_date=`date "+%Y-%m-%d %H:%M"`
		# 当前日期对应的时间戳
		current_timestamp=`date -d "$current_date" +%s`
		str_split "-" $ngx_time
		# 用户输入的日期
		user_date="`date \"+%Y-%m-%d\"` ${array[0]}"
		# 用户输入的日期对应的时间戳
		user_timestamp=`date -d "$user_date" +%s`
		filename=`date +%Y%m%d`"[${array[0]}-${array[1]}].log"
		mydate=`date +%d/%b/%Y`
		parse_ngx_path=$ngx_parse_dir_path/$filename
		
		if [ $user_timestamp == $current_timestamp ];then
			echo -e "\033[32m 文件${parse_ngx_path}正在生成... \033[0m"
			awk -v mydate=$mydate -v arr1=${array[0]} -v arr2=${array[1]} -F "[ /:]" '$1"/"$2"/"$3==mydate && $4":"$5>=arr1 && $4":"$5<=arr2' $ngx_path > $parse_ngx_path
			echo -e "\033[32m 文件${parse_ngx_path}生成成功!!! \033[0m"
		elif [ ! -f $parse_ngx_path ];then
			echo -e "\033[32m 文件${parse_ngx_path}正在生成... \033[0m"
			awk -v mydate=$mydate -v arr1=${array[0]} -v arr2=${array[1]} -F "[ /:]" '$1"/"$2"/"$3==mydate && $4":"$5>=arr1 && $4":"$5<=arr2' $ngx_path > $parse_ngx_path
			echo -e "\033[32m 文件${parse_ngx_path}生成成功!!! \033[0m"
		fi
		
	else
		echo "格式输入不正确"
		exit
	fi
elif [ $len == 22 ];then	
	# 统计"-"出现的次数
	if [ `echo $ngx_time | grep -o '-' | wc -l` == 3 ];then
		str_split " " "$ngx_time"
		# 自定义日期格式
		mydate1=`date -d "${array[0]}" +%d/%b/%Y`
		# 日期转时间戳
		timestamp=`date -d "${array[0]}" +%s`
		# 时间戳转日期
		mydate2=`date -d @$timestamp "+%Y%m%d"`
		str_split "-" ${array[1]}
		filename=$mydate2"[${array[0]}-${array[1]}].log"
		parse_ngx_path=$ngx_parse_dir_path/$filename
		
		if [ ! -f $parse_ngx_path ];then
			echo -e "\033[32m 文件${parse_ngx_path}正在生成... \033[0m"
			awk -v mydate=$mydate1 -v arr1=${array[0]} -v arr2=${array[1]} -F "[ /:]" '$1"/"$2"/"$3==mydate && $4":"$5>=arr1 && $4":"$5<=arr2' $ngx_path > $parse_ngx_path
			echo -e "\033[32m 文件${parse_ngx_path}生成成功!!! \033[0m"
		fi
		
	else
		echo "格式输入不正确"
		exit
	fi
else
	echo "格式输入不正确"
	exit
fi
# 开始解析切割后的Nginx日志
if [ ! -f $parse_ngx_path ];then
	echo -e "\033[31m 文件${parse_ngx_path}不存在 \033[0m"
fi
# 统计访问最多的ip
echo -e "\033[31m 访问TOP10的IP: \033[0m"
awk '{print $1}' $parse_ngx_path | sort | uniq -c | sort -n -k 1 -r | head -n 10
ip_array=`(awk '{print $1}' $parse_ngx_path | sort | uniq -c | sort -n -k 1 -r | head -n 10 | awk '{print $2}')`
# 统计访问最多的url
echo -e "\033[31m 访问TOP10的URL: \033[0m"
awk '{print $7}' $parse_ngx_path | sort |uniq -c | sort -rn | head -n 10
# 统计ip对应的url
for i in ${ip_array[@]};do 
	echo -e "\033[31m IP(${i})访问TOP10的URL: \033[0m"
	cat access.log | grep $i |awk '{print $7}'| sort | uniq -c | sort -rn | head -10 | more 
done
