image: "Standard_CentOS_Stream_latest"
flavor: "s3.xlarge.2"
security_groups: ["common_sg", "graphite_sg"]
nics:
  - fixed_ip: "192.168.14.12"
    net-name: "galera-internal-network"
root_volume_size: 20
auto_ip: false

graphite_instance_group: "graphite-apimon"

graphite_cert: "graphite5-eco"
ssl_certs:
  graphite5-eco:
    - "graphite5.eco.tsi-dev.otc-service.com"
    - "graphite.eco.tsi-dev.otc-service.com"

firewalld_extra_services_enable: ['http', 'https']
firewalld_extra_ports_enable: ['2003/tcp', '2004/tcp', '2013/tcp', '2014/tcp',
  '2023/tcp', '2024/tcp', '8080/tcp', '8081/tcp', '8082/tcp', '8125/udp',
  '11211/tcp']

telegraf_output_graphite_host: 192.168.151.11
