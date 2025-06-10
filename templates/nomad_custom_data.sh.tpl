#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/var/log/nomad-cloud-init.log"
SYSTEMD_DIR="${systemd_dir}"
NOMAD_DIR_CONFIG="${nomad_dir_config}"
NOMAD_CONFIG_PATH="$NOMAD_DIR_CONFIG/nomad.hcl"
NOMAD_DIR_TLS="${nomad_dir_config}/tls"
NOMAD_DIR_DATA="${nomad_dir_home}/data"
NOMAD_DIR_LICENSE="${nomad_dir_home}/license"
NOMAD_DIR_ALLOC_MOUNTS="${nomad_dir_home}/alloc_mounts"
NOMAD_LICENSE_PATH="$NOMAD_DIR_LICENSE/license.hclic"
NOMAD_DIR_LOGS="/var/log/nomad"
NOMAD_DIR_BIN="${nomad_dir_bin}"
CNI_DIR_BIN="${cni_dir_bin}"
NOMAD_USER="nomad"
NOMAD_GROUP="nomad"
NOMAD_INSTALL_URL="${nomad_install_url}"
REQUIRED_PACKAGES="curl jq unzip"
AWS_REGION="${aws_region}"
ADDITIONAL_PACKAGES="${additional_package_names}"

function log {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="$timestamp [$level] - $message"

    echo "$log_entry" | tee -a "$LOGFILE"
}

function detect_os_distro {
    local OS_DISTRO_NAME=$(grep "^NAME=" /etc/os-release | cut -d"\"" -f2)
    local OS_DISTRO_DETECTED

    case "$OS_DISTRO_NAME" in
    "Ubuntu"*)
        OS_DISTRO_DETECTED="ubuntu"
        ;;
    "CentOS"*)
        OS_DISTRO_DETECTED="centos"
        ;;
    "Red Hat"*)
        OS_DISTRO_DETECTED="rhel"
        ;;
    "Amazon Linux"*)
        OS_DISTRO_DETECTED="al2023"
        ;;
    *)
        log "ERROR" "'$OS_DISTRO_NAME' is not a supported Linux OS distro for this NOMAD module."
        exit_script 1
        ;;
    esac

    echo "$OS_DISTRO_DETECTED"
}

function prepare_disk() {
  log "INFO" "Preparing Nomad data disk"
  local device_name="$1"
  log "DEBUG" "prepare_disk - device_name; $${device_name}"

  local device_mountpoint="$2"
  log "DEBUG" "prepare_disk - device_mountpoint; $${device_mountpoint}"

  local device_label="$3"
  log "DEBUG" "prepare_disk - device_label; $${device_label}"

  local ebs_volume_id=$(aws ec2 describe-volumes --filters Name=attachment.device,Values=$${device_name} Name=attachment.instance-id,Values=$INSTANCE_ID --query 'Volumes[*].{ID:VolumeId}' --region ${aws_region} --output text | tr -d '-' )
  log "DEBUG" "prepare_disk - ebs_volume_id; $${ebs_volume_id}"

  local device_id=$(readlink -f /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_$${ebs_volume_id})
  log "DEBUG" "prepare_disk - device_id; $${device_id}"

  mkdir $device_mountpoint

  # exclude quotes on device_label or formatting will fail
  mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 -L $device_label $${device_id}

  echo "LABEL=$device_label $device_mountpoint ext4 defaults 0 2" >> /etc/fstab

  mount -a
}

function install_prereqs {
    local OS_DISTRO="$1"
    log "INFO" "Installing required packages..."

    if [[ "$OS_DISTRO" == "ubuntu" ]]; then
        sleep 60
        apt-get update -y
        apt-get install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
    elif [[ "$OS_DISTRO" == "rhel" ]]; then
        yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
    elif [[ "$OS_DISTRO" == "amzn2023" ]]; then
        yum install -y $REQUIRED_PACKAGES $ADDITIONAL_PACKAGES
    else
        log "ERROR" "Unsupported OS distro '$OS_DISTRO'. Exiting."
        exit_script 1
    fi
}

function install_awscli {
    local OS_DISTRO="$1"
    local OS_VERSION=$(grep "^VERSION=" /etc/os-release | cut -d"\"" -f2)

    if command -v aws >/dev/null; then
        log "INFO" "Detected 'aws-cli' is already installed. Skipping."
    else
        log "INFO" "Installing 'aws-cli'."
        curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        if command -v unzip >/dev/null; then
            unzip -qq awscliv2.zip
        elif command -v busybox >/dev/null; then
            busybox unzip -qq awscliv2.zip
        else
            log "WARNING" "No 'unzip' utility found. Attempting to install 'unzip'."
            if [[ "$OS_DISTRO" == "ubuntu" || "$OS_DISTRO" == "debian" ]]; then
                apt-get update -y
                apt-get install unzip -y
            elif [[ "$OS_DISTRO" == "centos" || "$OS_DISTRO" == "rhel" || "$OS_DISTRO" == "al2023" ]]; then
                yum install unzip -y
            else
                log "ERROR" "Unable to install required 'unzip' utility. Exiting."
                exit_script 2
            fi
            unzip -qq awscliv2.zip
        fi
        ./aws/install >/dev/null
        rm -f ./awscliv2.zip && rm -rf ./aws
    fi
}

function scrape_vm_info {
  log "INFO" "Scraping EC2 instance metadata for required information..."
  EC2_TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  INSTANCE_ID="$(curl -s -H "X-aws-ec2-metadata-token: $EC2_TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"
  AVAILABILITY_ZONE="$(curl -s -H "X-aws-ec2-metadata-token: $EC2_TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)"
  log "INFO" "Detected EC2 instance ID is '$INSTANCE_ID' and availability zone is '$AVAILABILITY_ZONE'."
}

# For Nomad there are a number of supported runtimes, including Exec, Docker, Podman, raw_exec, and more. This function should be modified 
# to install the runtime that is appropriate for your environment. By default the no runtimes will be enabled. 
function install_runtime {
    log "INFO" "Installing a runtime..."
    log "INFO" "Done installing runtime."
}

function retrieve_license_from_awssm {
    local SECRET_ARN="$1"
    local SECRET_REGION=$AWS_REGION

    if [[ -z "$SECRET_ARN" ]]; then
        log "ERROR" "Secret ARN cannot be empty. Exiting."
        exit_script 4
    elif [[ "$SECRET_ARN" == arn:aws:secretsmanager:* ]]; then
        log "INFO" "Retrieving value of secret '$SECRET_ARN' from AWS Secrets Manager."
        NOMAD_LICENSE=$(aws secretsmanager get-secret-value --region $SECRET_REGION --secret-id $SECRET_ARN --query SecretString --output text)
        echo "$NOMAD_LICENSE" >$NOMAD_LICENSE_PATH
    else
        log "WARNING" "Did not detect AWS Secrets Manager secret ARN. Setting value of secret to what was passed in."
        NOMAD_LICENSE="$SECRET_ARN"
        echo "$NOMAD_LICENSE" >$NOMAD_LICENSE_PATH
    fi
}

function retrieve_certs_from_awssm {
    local SECRET_ARN="$1"
    local DESTINATION_PATH="$2"
    local SECRET_REGION=$AWS_REGION
    local CERT_DATA

    if [[ -z "$SECRET_ARN" ]]; then
        log "ERROR" "Secret ARN cannot be empty. Exiting."
        exit_script 5
    elif [[ "$SECRET_ARN" == arn:aws:secretsmanager:* ]]; then
        log "INFO" "Retrieving value of secret '$SECRET_ARN' from AWS Secrets Manager."
        CERT_DATA=$(aws secretsmanager get-secret-value --region $SECRET_REGION --secret-id $SECRET_ARN --query SecretString --output text)
        echo "$CERT_DATA" | base64 -d >$DESTINATION_PATH
    else
        log "WARNING" "Did not detect AWS Secrets Manager secret ARN. Setting value of secret to what was passed in."
        CERT_DATA="$SECRET_ARN"
        echo "$CERT_DATA" | base64 -d >$DESTINATION_PATH
    fi
}

function retrieve_gossip_encryption_key_from_awssm {
    local SECRET_ARN="$1"
    local SECRET_REGION=$AWS_REGION
    if [[ -z "$SECRET_ARN" ]]; then
        log "ERROR" "Secret ARN cannot be empty. Exiting."
        exit_script 5   
    elif [[ "$SECRET_ARN" == arn:aws:secretsmanager:* ]]; then
        log "INFO" "Retrieving value of secret '$SECRET_ARN' from AWS Secrets Manager."
        GOSSIP_ENCRYPTION_KEY=$(aws secretsmanager get-secret-value --region $SECRET_REGION --secret-id $SECRET_ARN --query SecretString --output text)
    else
        log "WARNING" "Did not detect AWS Secrets Manager secret ARN. Setting value of secret to what was passed in."
        GOSSIP_ENCRYPTION_KEY="$SECRET_ARN"
    fi
}

# user_create creates a dedicated linux user for Nomad
function user_group_create {
    log "INFO" "Creating Nomad user and group..."

    # Create the dedicated as a system group
    sudo groupadd --system $NOMAD_GROUP

    # Create a dedicated user as a system user
    sudo useradd --system --no-create-home -d $NOMAD_DIR_CONFIG -g $NOMAD_GROUP $NOMAD_USER

    log "INFO" "Done creating Nomad user and group"
}

function directory_create {
    log "INFO" "Creating necessary directories..."

    # Define all directories needed as an array
    directories=($NOMAD_DIR_CONFIG $NOMAD_DIR_DATA $NOMAD_DIR_TLS $NOMAD_DIR_LICENSE $NOMAD_DIR_LOGS $CNI_DIR_BIN $NOMAD_DIR_ALLOC_MOUNTS)

    # Loop through each item in the array; create the directory and configure permissions
    for directory in "$${directories[@]}"; do
        log "INFO" "Creating $directory"

        mkdir -p $directory
        sudo chown $NOMAD_USER:$NOMAD_GROUP $directory
        sudo chmod 750 $directory
    done

    log "INFO" "Done creating necessary directories."
}

# install_nomad_binary downloads the Nomad binary and puts it in dedicated bin directory
function install_nomad_binary {
    log "INFO" "Installing Nomad binary to: $NOMAD_DIR_BIN..."

    # Download the Nomad binary to the dedicated bin directory
    sudo curl -so $NOMAD_DIR_BIN/nomad.zip $NOMAD_INSTALL_URL

    # Unzip the Nomad binary
    sudo unzip $NOMAD_DIR_BIN/nomad.zip nomad -d $NOMAD_DIR_BIN
    sudo unzip $NOMAD_DIR_BIN/nomad.zip -x nomad -d $NOMAD_DIR_LICENSE

    sudo rm $NOMAD_DIR_BIN/nomad.zip

    log "INFO" "Done installing Nomad binary."
}

function install_cni_plugins {
    log "INFO" "Installing CNI plugins..."

    # Download the CNI plugins
    sudo curl -Lso $CNI_DIR_BIN/cni-plugins.tgz "${cni_install_url}"

    # Untar the CNI plugins
    tar -C $CNI_DIR_BIN -xzf $CNI_DIR_BIN/cni-plugins.tgz
}

function configure_sysctl {
    log "INFO" "Configuring sysctl settings..."

    # Configure sysctl settings for Nomad
    tee -a /etc/sysctl.d/bridge.conf <<-EOF
    net.bridge.bridge-nf-call-arptables = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
EOF
}

function generate_nomad_config {
  log "INFO" "Generating $NOMAD_CONFIG_PATH file."


  cat >$NOMAD_CONFIG_PATH <<EOF

# Full configuration options can be found at https://developer.hashicorp.com/nomad/docs/configuration

%{ if nomad_acl_enabled }
acl {
  enabled = true
}%{ endif }

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

datacenter = "${nomad_datacenter}"
region     = "${nomad_region}"

# leave_on_interrupt = true
# leave_on_terminate = true

enable_syslog   = true
syslog_facility = "daemon"

%{ if nomad_server }
server {
  enabled          = true

  bootstrap_expect = "${nomad_nodes}"
  license_path     = "$NOMAD_LICENSE_PATH"
  encrypt          = "$GOSSIP_ENCRYPTION_KEY"
  redundancy_zone  = "$AVAILABILITY_ZONE"

  server_join {
    retry_join = ["provider=aws addr_type=private_v4 tag_key=Environment-Name tag_value=${template_name}"]
  }
}

%{ if autopilot_health_enabled }
autopilot {
    cleanup_dead_servers      = true
    last_contact_threshold    = "200ms"
    max_trailing_logs         = 250
    server_stabilization_time = "10s"
    enable_redundancy_zones   = true
    disable_upgrade_migration = false
    enable_custom_upgrades    = false
}
%{ endif }
%{ endif }

%{ if nomad_tls_enabled }
tls {
  http      = true
  rpc       = true
  cert_file = "$NOMAD_DIR_TLS/cert.pem" 
  key_file  = "$NOMAD_DIR_TLS/key.pem"
%{ if nomad_tls_ca_bundle_secret_arn != "NONE" ~}
  ca_file   = "$NOMAD_DIR_TLS/bundle.pem"
%{ endif ~}
  verify_server_hostname = true
  verify_https_client    = false
}
%{ endif }

%{ if nomad_client }
client {
  enabled = true
%{ if nomad_upstream_servers != null ~}
servers = [
%{ for addr in formatlist("%s",nomad_upstream_servers) ~}
   "${addr}",
%{ endfor ~}
]
%{ else }
  server_join {
    retry_join = ["provider=aws addr_type=private_v4 tag_key=${nomad_upstream_tag_key} tag_value=${nomad_upstream_tag_value}"]
  }
%{ endif }
}
%{ endif }

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

ui {
  enabled = ${ nomad_ui_enabled }
}
EOF

  chown $NOMAD_USER:$NOMAD_GROUP $NOMAD_CONFIG_PATH
  chmod 640 $NOMAD_CONFIG_PATH
}

function template_nomad_systemd {
  log "[INFO]" "Templating out the Nomad service..."

  local kill_cmd=$(which kill)
  sudo bash -c "cat > $SYSTEMD_DIR/nomad.service" <<EOF
[Unit]
Description=HashiCorp Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target
ConditionFileNotEmpty=$NOMAD_CONFIG_PATH
StartLimitIntervalSec=60
StartLimitBurst=3

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
#Wants=consul.service
#After=consul.service

[Service]
User=$NOMAD_USER
Group=$NOMAD_GROUP
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$NOMAD_DIR_BIN/nomad agent -config $NOMAD_DIR_CONFIG
ExecReload=$${kill_cmd} --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=2
TimeoutStopSec=30
LimitNOFILE=65536
LimitNPROC=infinity
LimitMEMLOCK=infinity
EnvironmentFile=-$NOMAD_DIR_CONFIG/nomad.env
Type=notify
TasksMax=infinity
# Nomad Server agents should never be force killed,
# so here we disable OOM (out of memory) killing for this unit.
# However, you may wish to change this for Client agents, since
# the workloads that Nomad places may be more important
# than the Nomad agent itself.
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF
}

# start_enable_nomad starts and enables the nomad service
function start_enable_nomad {
  log "[INFO]" "Starting and enabling the nomad service..."

  sudo systemctl enable nomad
  sudo systemctl start nomad

  log "[INFO]" "Done starting and enabling the nomad service."
}

function exit_script {
  if [[ "$1" == 0 ]]; then
    log "INFO" "nomad_custom_data script finished successfully!"
  else
    log "ERROR" "nomad_custom_data script finished with error code $1."
  fi

  exit "$1"
}

function main {
  log "INFO" "Beginning Nomad user_data script."

  OS_DISTRO=$(detect_os_distro)
  log "INFO" "Detected Linux OS distro is '$OS_DISTRO'."
  scrape_vm_info
  install_prereqs "$OS_DISTRO"
  install_awscli "$OS_DISTRO"
  prepare_disk "/dev/sdf" "/var/lib/nomad" "nomad-data"
  user_group_create
  directory_create
  install_nomad_binary
  %{ if nomad_client ~}
  install_runtime
  install_cni_plugins
  configure_sysctl
  %{ endif ~}
  %{ if nomad_server ~}
  retrieve_license_from_awssm "${nomad_license_secret_arn}"
  retrieve_gossip_encryption_key_from_awssm "${nomad_gossip_encryption_key_secret_arn}"
  %{ endif ~}
  %{ if nomad_tls_enabled ~}
  retrieve_certs_from_awssm "${nomad_tls_cert_secret_arn}" "$NOMAD_DIR_TLS/cert.pem"
  retrieve_certs_from_awssm "${nomad_tls_privkey_secret_arn}" "$NOMAD_DIR_TLS/key.pem"
  %{ if nomad_tls_ca_bundle_secret_arn != "NONE" ~}
  retrieve_certs_from_awssm "${nomad_tls_ca_bundle_secret_arn}" "$NOMAD_DIR_TLS/bundle.pem"
  %{ endif ~}
  %{ endif ~}
  generate_nomad_config
  template_nomad_systemd
  start_enable_nomad
  
  exit_script 0
}

main