# terraform-azapi-aisearch-demo

Self-contained Terraform demo for a local build of `terraform-provider-azapi` that proves the generic `data.azapi_data_plane_resource` data source can read an Azure AI Search index from the data plane.

The configuration creates:

1. an Azure resource group;
2. an Azure AI Search service;
3. a `Search Service Contributor` role assignment for the current caller (required to create and read index *definitions* via the data plane);
4. an AI Search index via the managed `azapi_data_plane_resource`; and
5. a read of that index via `data.azapi_data_plane_resource`, projecting `fields[].name` and the key field with `response_export_values`.

## Prerequisites

- Go 1.26 or newer (the provider's `go.mod` requires `go 1.26.0`).
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

## Continuous integration

`.github/workflows/integration.yml` is an end-to-end integration test modelled on
[`terraform-azapi-global-outputs`](https://github.com/kewalaka/terraform-azapi-global-outputs).

Jobs:

1. **build-provider** — builds the `azapi` provider from the data-plane branch
   (`kewalaka/add-table-storage-dataplane`, i.e. PR #1141, which contains the
   `data.azapi_data_plane_resource` data source). The binary is cached, keyed to
   the provider branch HEAD commit.
2. **plan** — runs on every push and pull request. Configures `dev_overrides`
   against the cached binary and runs `terraform plan`. Uploads the
   `{ tfplan, terraform.tfstate }` pair as an artifact.
3. **apply** — runs on push to `main` and `workflow_dispatch` only. Gated by the
   `integration` GitHub Environment. Applies the exact saved plan, then always
   runs `terraform destroy` so nothing is left behind.

### Azure authentication (OIDC, no secrets)

The workflow authenticates to Azure with workload-identity federation — there are
no client secrets. It expects these **repository variables**:

| Variable | Value |
| --- | --- |
| `ARM_CLIENT_ID` | client ID of the user-assigned managed identity used for OIDC |
| `ARM_TENANT_ID` | Entra tenant ID |
| `ARM_SUBSCRIPTION_ID` | target subscription ID |

The managed identity needs three federated credentials (GitHub issuer
`https://token.actions.githubusercontent.com`, audience
`api://AzureADTokenExchange`) with subjects:

- `repo:<owner>/<repo>:pull_request`
- `repo:<owner>/<repo>:ref:refs/heads/main`
- `repo:<owner>/<repo>:environment:integration`

and Azure RBAC sufficient to create the resource group, the AI Search service, and
the role assignment (`Contributor` + `Role Based Access Control Administrator`, or
`Owner`, at subscription scope).
