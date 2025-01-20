# Nomad Configuration Settings

To automate the Nomad install and configuration, the `templates/nomad_custom_data.sh.tpl` (cloud-init) script dynamically generates a `nomad.hcl` file containing all the necessary configuration settings required to start and run the Nomad client or server. Some of these configuration values are derived from interpolated values from other resources created by this module, while others are based on module input variables or automatically computed by the module itself.

Since the Nomad installation and configuration are managed as code, and the persistent data (if any) is external to the compute nodes, you can treat your Nomad servers or clients as stateless, ephemeral, and immutable. If you need to add, modify, or update a configuration setting, do so in the Terraform code that manages your Nomad deployment. You should not manually modify settings in-place on the running Nomad instances, unless you are temporarily testing or troubleshooting something before committing a code change.

## Configuration Settings Reference

The [Nomad Configuration Reference](https://developer.hashicorp.com/nomad/docs/configuration) page contains all available settings, their descriptions, and default values. If you need to configure one of these settings with a non-default value, find the corresponding variable in the `variables.tf` file of this module. You can specify the desired value within your Nomad module block.

## Where to Look in the Code

Within the `compute.tf` file, there is a `locals` block with a map called `custom_data_args`. Many of the Nomad configuration settings are passed from here as arguments into the `templates/nomad_config_data.sh.tpl` (cloud-init) script.

Within the `templates/nomad_custom_data.sh.tpl` script, there is a function named `generate_nomad_config` that receives all of these inputs and dynamically generates the `nomad.hcl` file. After a successful installation, this file can be found at `/etc/nomad.d/nomad.hcl` on your Nomad instances.

## Procedure

1. Determine which [configuration setting](https://developer.hashicorp.com/nomad/docs/configuration) you would like to add, modify, or update.

2. Find the corresponding variable in `variables.tf`.

3. Specify the input within your Nomad module block. For example, if you want to modify the `nomad_datacenter` setting to a value other than the default:

    ```hcl
    module "nomad" {
      ...
      datacenter = var.node_datacenter
      ...
    }
    ```

    > 📝 **Note:** If you'd prefer to hard-code the value directly, you can assign it directly in the module block and skip step 4.

4. Verify the corresponding variable definition exists in your own `variables.tf` file. If it doesn’t exist, add it.

5. From within the Terraform directory managing your Nomad deployment, run `terraform apply` to update the Nomad EC2 launch template.

6. During a maintenance window, terminate the running Nomad EC2 instance(s). This will trigger the autoscaling group to spawn new instance(s) from the latest version of the Nomad EC2 launch template. This process will effectively reinstall Nomad on the new instance(s), including the updated configuration settings.