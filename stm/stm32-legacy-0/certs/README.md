# Custom CA certificates (optional)

Drop any custom CA certificate(s) you want the image to trust into this
directory, then build normally. If you have nothing to add, leave the
directory as-is — the image uses Ubuntu's built-in certificate bundle.

Requirements for files placed here:

- **PEM format** (Base64 `-----BEGIN CERTIFICATE-----` text).
- **`.crt` extension** — `update-ca-certificates` only picks up `*.crt`.
  A DER/`.cer` file must be converted first:
  `openssl x509 -inform der -in corp.cer -out corp.crt`
- One certificate per file is cleanest, but a file with several concatenated
  PEM blocks also works.

During the Docker build these files are copied to
`/usr/local/share/ca-certificates/` and merged into the system trust store
by `update-ca-certificates`, so both the build-time downloads (wget/curl) and
anything running inside the container will trust them.
