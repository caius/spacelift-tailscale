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
  # …
```

### DNS / Making connections

Due to running tailscaled with userspace networking, we don't get MagicDNS wiring up requests for us. Packets are routed to the correct IPs without us having to do anything however, so we just need to solve the DNS issue.

The suggested solution from Tailscale documentation is to use either a SOCKS5 or HTTP Proxy. We run a HTTP Proxy on `localhost:8080` in the container by default, so that's likely the easiest way to go. This requires `http_proxy` setting in the environment, and your Terraform provider able to make use of it. (Anything using Go's `net/http` library should be able to use it automatically.)

You'll somehow need to inject that into the environment of the phase, the easiest way is to include it in your `config.yml` as well:

```yaml
your-stage-id:
  # …
  environment:
    http_proxy: "http://localhost:8080"
  # …
```

The other, more complex, route is to inject the Tailscale IP for a given host you want to correspond with into the `/etc/hosts` file. This will need to be called before every phase that wants to talk to it, and you'll need to know ahead of time what you want to connect to. Anything that can look up the hostname in `/etc/hosts` will be able to connect to it however.

We use a tool called `txeh` to manage `/etc/hosts`, it's already in the image and has suid bit set so it has permissions to edit `/etc/hosts` even though we're running as spacelift user.

```yaml
your-stage-id:
  # …
  before_plan:
    - "spacetail up"
    # Repeat for all your tailscale hosts you want to talk to
    - "/usr/local/bin/txeh $(tailscale --socket /mnt/workspace/tailscaled.sock ip -4 server1) server1"
  after_plan:
    - "spacetail down"
```

## Configuration

Configuration is via various envariables in the Spacelift runner container, inspired by tailscale's `containerboot` binary:

- `TS_AUTH_KEY` - Tailscale auth key (Suggest creating ephemeral & tagged key)
- `TS_TAILSCALED_EXTRA_ARGS` - Extra arguments to pass to `tailscaled`. eg, `--socks5-server=localhost:1080`
- `TS_EXTRA_ARGS` - Extra arguments to pass to `tailscale up`. eg, `--ssh` for debugging

## Context

Spacelift runs terraform (or other tooling) in containers, and controls the commands that run therein. They operate in phases, and don't detect the "end" of a phase until all processes in the container have exited. It appears each phase _can_ be executed in a different container, but with the same workspace directory/environment variables copied between containers.

This poses a problem for connecting to Tailscale, as we need a background process (`tailscaled`) running to setup/maintain connections for us whilst we run terraform. We need it to be stopped before the phase ends, otherwise Spacelift will hit the timeout (4200 seconds!)

The other spanner in the works is Spacelift controls/overwrites the entrypoint to the container as well so we can't trigger things on-boot

To work around this we start tailscaled/tailscale before each phase it's required in, and then shut it down after the phase.
