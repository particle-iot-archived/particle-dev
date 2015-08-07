#!/bin/bash
openssl aes-256-cbc -k %ENCRYPTION_SECRET% -in .\build\resources\authenticode-signing-cert.p12.enc -out .\build\resources\authenticode-signing-cert.p12 -a
certutil -p %KEY_PASSWORD% -importpfx .\build\resources\authenticode-signing-cert.p12
