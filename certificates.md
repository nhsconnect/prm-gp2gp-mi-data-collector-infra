# Updating MESH certificates

## About this guide

MESH uses mutual authentication to verify the identity of both the server and
client. This means the `MESH to S3 forwarder` requires certificates to connect to
the MESH mailbox. The certificate we use is provided by DigiCert, and expires
after one year.

This guide will walk through how to update the certificate, and supplements the
[existing instructions][1] by elaborating on:

- How to start Internet Explorer inside the VDI
- The certificate format expected by our `MESH to S3 forwarder`
- Where to place the certificates once generated

## Requesting a new certificate

Raise a service request with the [National Service Desk][2] asking for a
renewal of the MESH certificate.

This should result in you receiving an email from DigiCert inviting you to
generate a certificate.

## Using Internet Explorer to download the certificate

Internet Explorer is specifically required to generate the certificate.
Modern browsers including Chrome, Firefox, Safari and Edge will not work.

As of the date this document was authored, the preferred option is to launch
Internet Explorer inside the VDI using the VMWare Horizon client.

Once setup with IE, follow steps 4 to 18 in the [existing guide][1].

## Converting the certificate into the correct format

Once you have exported the pfx certificate bundle from Internet Explorer, the
next step is to use `openssl` to extract the key and certificate in the PEM
format. However, at this time the VDI does not have `openssl` available.

One workaround is to complete the rest of process inside a virtual machine in AWS:
- Log into the AWS web console and upload the pfx file to a secure, non public S3 bucket.
- You can now log out of the VDI.
- Build an IAM role for the instance permitting access to parameter store, S3 and systems manager session manager.
- Start an EC2 instance configured with the role.
- Use session manager to connect to the instance.

Download the certificate from the S3 bucket, e.g:

```bash
aws s3 cp s3://thebucket/digicert.pfx digicert.pfx
```

Extract the client certificate:

```bash
openssl pkcs12 -in digicert.pfx -clcerts -nokeys -out digicert.crt

```

Extract the client key:

```bash
openssl pkcs12 -in digicert.pfx -nocerts -nodes -out digicert.key
```

## Uploading certificate to parameter store

Still inside the virtual machine, use the AWS CLI to upload the certificate to
parameter store. Run the following commands twice, once with `FORWARDER_ENV`
set to `dev` and once set to `prod`.


```bash
aws ssm put-parameter \
    --region eu-west-2 \
    --name /registrations/${FORWARDER_ENV}/user-input/mesh/mailbox-client-cert \
    --type SecureString \
    --value file://digicert.crt
```

```bash
aws ssm put-parameter \
    --region eu-west-2 \
    --name /registrations/${FORWARDER_ENV}/user-input/mesh/mailbox-client-cert-private-key \
    --type SecureString \
    --value file://digicert.key
```

## Restarting the forwarder

The forwarder service will not pick up the new certificates automatically.
Instead, navigate to the ECS task instance and stop the task. The ECS service
will automatically start another task, which will pick up the new certificates.

[1]: https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/mesh-guidance-hub/certificate-guidance#digicert-certificate-request-access-via-internet-
[2]: https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh#contact
