# Nomad Enterprise HVD - Default Example

This example will deploy Nomad Clients to join an existing Nomad Cluster. The clients can join via a specified AWS tag with setting `nomad_upstream_tag_key` and `nomad_upstream_tag_value` or with DNS/IP addresses with `nomad_upstream_servers`
No Runtimes will be enabled by default. To enable a runtime, modify the `install_runtime` function in the `templates\nomad_custom_data.sh.tpl` with the code to enable any runtimes as needed.
