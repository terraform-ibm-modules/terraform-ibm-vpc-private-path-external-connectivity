# Sample deployable architectures

[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/sample-deployable-architectures?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/sample-deployable-architectures/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This repository contains the following sample deployable architectures:
- [Sample terraform-based deployable architecture without dependencies (fullstack) - COS bucket replication](./solutions/tf-fullstack-da)
- [Sample terraform-based deployable architecture with dependencies (extension) - Serving static websites with IBM Cloud Object Storage](./solutions/tf-extension-da)

:exclamation: **Important:** These solutions are not intended to be called by other modules because they contain provider configurations and are not compatible with the `for_each`, `count`, and `depends_on` Terraform arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).

The repository is also configured with the following things:
- [A GitHub Actions workflow to run the common CI pipeline for Terraform](./.github/workflows). For more information, see the common-pipeline-assets [readme file](https://github.com/terraform-ibm-modules/common-pipeline-assets/blob/main/README.md)).
- A [common-dev-assets](./common-dev-assets) Git submodule with common automation that is used for CI and development. For more information, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup)).
- An [ibm_catalog.json](ibm_catalog.json) file that is used for onboarding the sample deployable architectures to the IBM Cloud catalog.
- A [.catalog-onboard-pipeline.yaml](.catalog-onboard-pipeline.yaml) file that is used by an IBM internal pipeline to onboard deployable architectures to the IBM catalog.
- A [renovate.json](renovate.json) file that supports automatic creation of PRs to update dependencies. The Renovate pipeline runs regularly against all repos in the [terraform-ibm-modules](https://github.com/terraform-ibm-modules) org.

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
