# Nomad Version Upgrades

Nomad follows a regular release cadence. See the [Nomad Releases](https://developer.hashicorp.com/nomad/docs/v1.8.x/release-notes) page for full details on the releases. Nomad upgrades are designed to be flexible, with two primary strategies: in-place upgrades, where the Nomad binary is updated without disrupting running allocations, and rolling upgrades, where new instances with the updated version replace old ones. To upgrade, update your Terraform code to reflect the new version, apply the changes to update the EC2 launch template, and replace or upgrade the EC2 instances. Perform these steps during a maintenance window to ensure minimal disruption to workloads.

This module includes an input variable named `nomad_version` that dictates which version of Nomad is deployed.

## Procedure

1. Determine your desired version of Nomad from the [Nomad Upgrades](https://developer.hashicorp.com/nomad/docs/upgrade) page. The value you need will be in the **Version** column of the table.

2. During a maintenance window, connect to your existing Nomad servers and gracefully drain them to ensure no new jobs are scheduled.

    To gracefully drain the node:

    ```sh
    nomad node drain -self -yes
    ```

    For more details on this command, see the following documentation:

    - [Nomad Node Drain](https://developer.hashicorp.com/nomad/docs/commands/node/drain)

3. Generate a backup of your backend data (e.g., Consul, Vault, or other backends used).

4. Update the value of the `nomad_version` input variable within your `terraform.tfvars` file to the desired Nomad version.

    ```hcl
    nomad_version = "1.8.0"
    ```
   > 📝 **Note:** Nomad does not support downgrading at this time. Downgrading clients requires draining allocations and removing the data directory. Downgrading servers safely requires re-provisioning the cluster

5. From within the directory managing your Nomad deployment, run `terraform apply` to update the Nomad EC2 launch template.

6. Terminate the running Nomad EC2 instance(s), which will trigger the autoscaling group to spawn new instance(s) from the latest version of the Nomad EC2 launch template. This process will effectively re-install Nomad on the new EC2 instance(s) that the autoscaling group creates with the version you specified in step 4 (`nomad_version`).
