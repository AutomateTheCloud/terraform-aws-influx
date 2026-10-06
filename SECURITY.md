# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that makes an InfluxDB instance more exposed than its inputs say it should be: for example, a default that allows network access or gives the instance a public IP address, a security group rule broader than documented, the admin password appearing anywhere the documentation does not say, or a validation that lets an insecure value through.

## Supported versions

Fixes are made to the latest release.
