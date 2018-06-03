1.influxdb
docker run -d --name influxdb -p 8086:8086 -v /root/influxdata:/var/lib/influxdb influxdb
docker exec -it influxdb influx
create database tcpdump

2.grafana
docker run -d --name grafana -p 3000:3000 grafana/grafana
