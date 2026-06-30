# terraform-azapi-aisearch-demo

Self-contained Terraform demo for a local build of `terraform-provider-azapi` that proves the generic `data.azapi_data_plane_resource` data source can read an Azure AI Search index from the data plane.

The configuration creates:

1. an Azure resource group;
2. an Azure AI Search service;
3. a `Search Service Contributor` role assignment for the current caller (required to create and read index *definitions* via the data plane);
4. an AI Search index via the managed `azapi_data_plane_resource`; and
5. a read of that index via `data.azapi_data_plane_resource`, projecting `fields[].name` and the key field with `response_export_values`.

## Prerequisites

- Go 1.25 or newer.
- Terraform 1.13 or newer.
- Azure CLI authenticated with `az login`.
- An Azure subscription selected via `az account set` or `ARM_SUBSCRIPTION_ID`.
- Permissions to create a resource group, Azure AI Search service, role assignment, and Search index.
- Local provider worktree containing the spike branch. Default:
  `/Users/stu.mace/.copilot/copilot-worktrees/kewalaka_terraform-provider-azapi/kewalaka-potential-train`

## Local provider override

`make terraformrc` builds the provider into `.terraform-dev-providers/` and writes a repo-local `.terraformrc` with:

```hcl
provider_installation {
  dev_overrides {
    "Azure/azapi" = "./.terraform-dev-providers"
  }
  direct {}
}
```

The Makefile exports `TF_CLI_CONFIG_FILE=$(pwd)/.terraformrc` so your home `~/.terraformrc` is not modified.

Override the provider source path if needed:

```bash
make build-provider PROVIDER_SRC=/path/to/terraform-provider-azapi
```

## Validate without creating Azure resources

```bash
make build-provider
make init
make fmt-check
make validate
```

Terraform will print a dev override warning for `Azure/azapi`; that is expected.

## Run against Azure

Review the subscription first:

```bash
az account show
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

Then run:

```bash
make plan
make apply
```

When finished:

```bash
make destroy
```

If data-plane operations return `403`, wait for RBAC propagation and rerun `make apply`, or increase `rbac_propagation_delay`.
