# Spacetail

Putting Tailscale into Spacelift, for accessing things on the tailnet from Terraform, etc easily.

Based on the base AWS spacelift image, with tailscale added to save re-downloading every run.

## Usage

There's a few things to configure to utilise tailscale from spacelift terraform, the easiest way to configure this is from `.spacelift/config.yml` in your git repository.

Firstly the `runner_image` will need setting to `ghcr.io/caius/spacelift-tailscale:latest` (or pin a specific SHA if you want.)

`spacetail up` needs invoking before the phase you need to make connections over the tailnet, and `spacetail down` needs invoking after any phase you've called up in.

For terraform this usually means you need to wrap the `plan`, `apply` and `destroy` phases. If you also want to be able to perform ad-hoc tasks using the tailnet, you'll need to wrap `perform` as well.

Example:

```yaml
your-stage-id:
  runner_image: "ghcr.io/caius/spacelift-tailscale:latest"
  before_plan:
    - "spacetail up"
  after_plan:
    - "spacetail down"
  before_apply:
    - "spacetail up"
  after_apply:
    - "spacetail down"
  before_destroy:
    - "spacetail up"
  after_destroy:
    - "spacetail down"
```

## Context

Spacelift runs terraform (or other tooling) in containers, and controls the commands that run therein. They operate in phases, and don't detect the "end" of a phase until all processes in the container have exited. It appears each phase _can_ be executed in a different container, but with the same workspace directory/environment variables copied between containers.

This poses a problem for connecting to Tailscale, as we need a background process (`tailscaled`) running to setup/maintain connections for us whilst we run terraform. We need it to be stopped before the phase ends, otherwise Spacelift will hit the timeout (4200 seconds!)

The other spanner in the works is Spacelift controls/overwrites the entrypoint to the container as well so we can't trigger things on-boot

To work around this we start tailscaled/tailscale before each phase it's required in, and then shut it down after the phase.
