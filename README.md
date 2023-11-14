# Spacetail

Putting Tailscale into Spacelift, for accessing things on the tailnet from Terraform, etc easily.

Based on the base AWS spacelift image, with tailscale added to save re-downloading every run.

## Usage

Coming soon.

## Context

Spacelift runs terraform (or other tooling) in containers, and controls the commands that run therein. They operate in stages, and don't detect the "end" of a stage until all processes in the container have exited. Each stage _can_ be executed in a different container, but with the same workspace directory/environment variables copied between containers.

This poses a problem for connecting to Tailscale, as we need a background process (`tailscaled`) running to setup/maintain connections for us whilst we run terraform. We need it to be stopped before the stage ends, otherwise Spacelift will hit the timeout (4200 seconds!)

The other spanner in the works is Spacelift controls/overwrites the entrypoint to the container as well so we can't trigger things on-boot

To work around this we start tailscaled/tailscale before each stage it's required in, and then shut it down after the stage.
