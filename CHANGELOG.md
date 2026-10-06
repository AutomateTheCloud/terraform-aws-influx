# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An Amazon Timestream for InfluxDB instance, running InfluxDB 2, with secure defaults: always encrypted, private, and no network access until you allow a source.
- The first admin user, organization and bucket, with a generated password unless you give one. AWS keeps a copy of them in AWS Secrets Manager.
- A security group that allows the InfluxDB port from IPv4 and IPv6 ranges, security groups and prefix lists, and nothing else.
- A Multi-AZ standby, the three storage types, a custom port, IPv4 and IPv6 (dual-stack) networking, DB parameter groups, and log delivery to Amazon S3.
- `region`, to create the instance in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic instance and most options together.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-influx/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-influx/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-influx/releases/tag/v1.0.0
