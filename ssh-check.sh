#!/bin/bash
filenumber=$1
checkduration=$2
for hostip in $(jq -r '.hosts[] | .ip' ./conf/host.json)
do
  whistlist=${whistlist}"src host not "${hostip}" and "
done
#sshcmd=$(echo "tcpdump -i eth0 dst port 22 and ${whistlist::-4}-G $2 -W $1 -w /root/bigdata/tcpdump/test-%Y-%m-%d-%H:%M:%S.pcap")
sshcmd=$(echo "tcpdump -i eth0 dst port 22 and ${whistlist::-4}-G $2 -W $1 -w /root/bigdata/tcpdump/test-%Y-%m-%d-%H:%M.pcap")
echo $sshcmd
for hostip in $(jq -r '.hosts[] | .ip' ./conf/host.json)
do
  ssh root@$hostip "rm /root/bigdata/tcpdump/* -f"
  ssh root@$hostip "killall tcpdump -q"
  ssh root@$hostip $sshcmd &
done

echo "tcpdump started"
sleep $(echo $1*$2+30 | bc)
rm -fr /tmp/tcpdump
for name in $(jq -r '.hosts[] | .name' ./conf/host.json)
do
  ip=$(jq --arg name $name -r '.hosts[] | select(.name==$name) | .ip'  ./conf/host.json)
  mkdir -p /tmp/tcpdump/$name
  scp root@$ip:/root/bigdata/tcpdump/* /tmp/tcpdump/$name

  #cd /tmp/tcpdump/$name
  #for a in $(ls --sort time | tail -n+2)
  for a in $(ls /tmp/tcpdump/$name --sort time)
  do
      #echo /tmp/tcpdump/$name/$a | cut -d "." -f1 | cut -d "-" -f2
      year=$(echo /tmp/tcpdump/$name/$a | cut -d "." -f1 | cut -d "-" -f3)
      mon=$(echo /tmp/tcpdump/$name/$a | cut -d "." -f1 | cut -d "-" -f4)
      day=$(echo /tmp/tcpdump/$name/$a | cut -d "." -f1 | cut -d "-" -f5)
      time=$(echo /tmp/tcpdump/$name/$a | cut -d "." -f1 | cut -d "-" -f6):00
      #echo $year $mon $day $time
      filedate=$(date "+%s" -d "$mon/$day/$year $time")000
      #filedate=$(echo $filedate1 + 8*3600*1000 | bc)
      echo $filedate
      k=0
      #checkline=$(tcpdump -nnnnr /tmp/tcpdump/$name/$a | cut -d ">" -f1 | grep -v "172.24.128.246" | cut -d " " -f3 | sort | head -n 1)
      checkline=$(tcpdump -nnnnr /tmp/tcpdump/$name/$a | cut -d ">" -f1 | cut -d " " -f3 | sort | head -n 1)
      check1=$(echo $checkline | cut -d "." -f1)
      check2=$(echo $checkline | cut -d "." -f2)
      check3=$(echo $checkline | cut -d "." -f3)
      check4=$(echo $checkline | cut -d "." -f4)
      check="$check1.$check2.$check3.$check4"
      #for b in $(tcpdump -nnnnr /tmp/tcpdump/$name/$a | cut -d ">" -f1 | grep -v "172.24.128.246" | cut -d " " -f3 | sort)
      for b in $(tcpdump -nnnnr /tmp/tcpdump/$name/$a | cut -d ">" -f1 | cut -d " " -f3 | sort)
      do
          #echo $b
          b1=$(echo $b | cut -d "." -f1)
          b2=$(echo $b | cut -d "." -f2)
          b3=$(echo $b | cut -d "." -f3)
          b4=$(echo $b | cut -d "." -f4)
          checkb="$b1.$b2.$b3.$b4"
          #echo $checkb
          if [ "$checkb" == "$check" ]
          then
              k=$(echo "$k+1" | bc)
          else
              echo $check $k
              curl -i -XPOST 'http://localhost:8086/write?db=tcpdump&precision=ms' --data-binary "ssh,host=$name,src-ip=$check value=$k $filedate"
              check=$checkb
              k=0
          fi
      done
      echo $check $k
      curl -i -XPOST 'http://localhost:8086/write?db=tcpdump&precision=ms' --data-binary "ssh,host=$name,src-ip=$check value=$k $filedate"
  done
done
