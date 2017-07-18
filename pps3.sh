pps3() { 
	portperfshow -tx -rx -t 0 | awk 'BEGIN{while(("switchshow"|getline)>0){if($0~/ Slot Port /){sp=1;$0=substr($0,1,5)substr($0,11)};if(p==1&&sp==1){pre=substr($0,1,4);post=substr($0,18);$0=substr($0,5,17);$0=sprintf("%s%9s%s",pre,$1"/"$2"   ",post);ss[$2]=$0}else{ss[$2]=$0};if($0~/^====/){p=1}}};NF{p=$0;getline;getline;split(p,q);if($1~/slot/){s=$2+0"/";$1="";$2="";$0=$0};for(i=1;i<=NF;i=i+2)if($i>0||$(i+1)>0)print s q[int(((i-1)/2)+1)]"\t"$i"\t"$(i+1)"\t|"ss[s q[int(((i-1)/2)+1)]]}';
};
