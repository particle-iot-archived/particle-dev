openssl aes-256-cbc -k %ENCRYPTION_SECRET% -in .\build\resources\authenticode-signing-cert.p12.enc -out .\build\resources\authenticode-signing-cert.p12 -d -a
certutil -p %KEY_PASSWORD% -user -importpfx .\build\resources\authenticode-signing-cert.p12 NoRoot
