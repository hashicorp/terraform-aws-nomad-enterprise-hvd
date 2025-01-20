.# Nomad Certificate Rotation

One of the prerequisites for automating Nomad deployment is to store base64-encoded strings of your Nomad TLS certificate and private key files (in PEM format) as plaintext secrets in AWS Secrets Manager. The Nomad client and server `cloud-init` scripts (or equivalent user-data scripts) are designed to retrieve the latest values of these secrets when they run. Therefore, to update Nomad's TLS certificates, update the corresponding secrets in AWS Secrets Manager, then restart or replace the Nomad servers or clients to pick up the new certificates. Follow the steps below for detailed instructions.

## Secrets

| Certificate file    | AWS Secrets Manager secret    |
|---------------------|-------------------------------|
| Nomad TLS certificate | `nomad_tls_cert_secret_arn`    |
| Nomad TLS private key | `nomad_tls_privkey_secret_arn` |

## Procedure

Follow these steps to rotate the certificates for your Nomad cluster.

1. Obtain your new Nomad TLS certificate file and private key file, both in PEM format.

1. Update the values of the existing secrets in AWS Secrets Manager (`nomad_tls_cert_secret_arn` and `nomad_tls_privkey_secret_arn`, respectively). If you need to base64-encode the files into strings before updating the secrets, see the examples below:

    On Linux (bash):

    ```sh
    cat new_nomad_cert.pem | base64 -w 0
    cat new_nomad_privkey.pem | base64 -w 0
    ```

    On macOS (terminal):

    ```sh
    cat new_nomad_cert.pem | base64
    cat new_nomad_privkey.pem | base64
    ```

   On Windows (PowerShell):

    ```powershell
    function ConvertTo-Base64 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $EncodedString = [Convert]::ToBase64String($Bytes)
    return $EncodedString
    }

    Get-Content new_nomad_cert.pem -Raw | ConvertTo-Base64 -Width 0
    Get-Content new_nomad_privkey.pem -Raw | ConvertTo-Base64 -Width 0
    ```

    > **Note:**
    > When updating the values of an AWS Secrets Manager secret, the secret ARN does not change, so **no action should be needed** in terms of updating any configuration values. If the secret ARNs **do** change for any reason, you will need to update the following Nomad configuration values with the new ARNs and restart Nomad servers or clients:
    >
    >```hcl
    >nomad_tls_cert_secret_arn    = "<new-nomad-tls-cert-secret-arn>"
    >nomad_tls_privkey_secret_arn = "<new-nomad-tls-privkey-secret-arn>"
    >```

1. During a maintenance window, restart or replace the Nomad servers and clients. This will trigger the Nomad instances to re-read the updated secrets from AWS Secrets Manager and apply the new certificates.

   - For instances managed by autoscaling or orchestration, terminate the running instances. This will trigger the creation of new instances that will pull the latest secrets, re-apply the certificates, and rejoin the cluster.
   - For manual or managed deployments, restart the Nomad services (`nomad agent -config=/etc/nomad.d`) to load the new certificates.

By following these steps, your Nomad cluster will seamlessly apply the updated TLS certificates and ensure secure communication.