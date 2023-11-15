# Spacetail

Putting Tailscale into Spacelift, for accessing things on the tailnet from Terraform, etc easily.

Based on the base AWS spacelift image, with tailscale added to save re-downloading every run.

The Readme is written mentioning Terraform but it will work out the box for Pulumi, Ansible, etc as well. The original commands defined in your Spacelift workflow are still invoked by Spacelift, we just wrap some setup/teardown around them for Tailscale.

See Howee Dunnit below for implementation details.

## Usage

The Spacelift Stack needs a couple of configuration options setting to have the tailnet available in your runs. These settings can be configured from:

- [Runtime Configuration] using `spacelift/config.yml` in the repo
- Spacelift UI -> Stack -> Settings -> Behaviour page (click Advanced for phase hooks)
- Spacelift's Terraform Provider / API, in the `spacelift_stack` resource

[Runtime Configuration]: https://docs.spacelift.io/concepts/configuration/runtime-configuration/

Setting it via the `config.yml` is most flexible, because you can test out changes in pull requests before merging down. (As suggested by the [Spacelift docs][runtime config suggestion].)

[runtime config suggestion]: https://docs.spacelift.io/concepts/configuration/runtime-configuration/#purpose-of-runtime-configuration

Firstly the `runner_image` needs setting to `ghcr.io/caius/spacelift-tailscale:latest` (or pin a specific SHA[^1] instead of `latest` to control updates.)

[^1]: <https://github.com/caius/spacelift-tailscale/pkgs/container/spacelift-tailscale/versions?filters%5Bversion_type%5D=tagged> lists all available SHA tags for the image.

Secondly, for every phase (eg, `plan`, `apply`) you need to talk over the tailnet, you'll need to invoke two commands in the before phase hooks.

- `spacetail up`
- `trap "spacetail down" EXIT`

There are also `init`, `perform` and `destroy` phases, which you may want to configure as well.

Terraform can then be configured via an environment variable to use tailscaled's http proxy which enables talking HTTP/s over the tailnet using MagicDNS hostnames. Out the box this image runs the http proxy at <http://localhost:8080/>.

A worked example for a `nomad-us-production` stack in `.spacelift/config.yml`:

```yaml
stacks:
  nomad-us-production:
    runner_image: "ghcr.io/caius/spacelift-tailscale:latest"
    environment:
      http_proxy: "http://localhost:8080"
    before_plan:
      - "spacetail up"
      - "trap 'spacetail down' EXIT"
    before_apply:
      - "spacetail up"
      - "trap 'spacetail down' EXIT"
```

This relies on Terraform providers using HTTP libraries that pay attention to the `http_proxy` environment variable for using a HTTP Proxy to communicate via. The default `net/http` library in Golang's stdlib does pay attention to this, so providers like `hashicorp/nomad` Just Work™ by pointing at the tailscale MagicDNS hostname of a nomad server.

## Tailnet Configuration

Configuration is via various envariables in the Spacelift runner container, "inspired"[^2] by tailscale's `containerboot` binary.

[^2]: copied from. Build on the shoulders of giants, and be consistent.

Required configuration:

- `TS_AUTH_KEY` - Tailscale auth key (Suggest creating ephemeral & tagged key)

Optional configuration:

- `TS_EXTRA_ARGS` - Extra arguments to pass to `tailscale up`. eg, `--ssh` for debugging inside the spacelift container
- `TS_TAILSCALED_EXTRA_ARGS` - Extra arguments to pass to `tailscaled`. eg, `--socks5-server=localhost:1081` to change socks5 port
- `TRACE` - set to non-empty (eg, "1") to debug `spacetail` script

## Howee Dunnit

Spacelift runs terraform (or other tooling) in containers, and overrides the initial command run in each container. The `/mnt/workspace` directory is mounted into each container and the environment variables are the same as the phases run.

Tailscale needs `tailscaled` running, which we can start in a `before_` phase hook in Spacelift. The tricky bit is we need to stop it before the phase ends, otherwise Spacelift will wait for the phase to time out in the case of the terraform command erroring, and also won't call any of the `after_` phase hooks. (This is due to how Spacelift executes everything, usually this is what you want!)

To work around this, we use a shell `trap` in the `before_` phase hooks to define a command to execute when the shell exits. We use this to stop tailscaled regardless of whether the terraform command errored or not. This means the container exits fairly quickly on completion and Spacelift can deal with the success or failure therein.

Due to running tailscaled with userspace networking, we don't get MagicDNS wiring up requests for us. Packets are routed to the correct IPs without us having to do anything however, so we just need to solve the DNS issue.

The suggested solution from Tailscale documentation is to use either a SOCKS5 or HTTP Proxy. We run http proxy on `localhost:8080` and socks5 on `localhost:1080` in the container by default, so that's likely the easiest way to go. This requires `http_proxy` setting in the environment, and your Terraform provider able to make use of it. (Anything using Go's `net/http` library should be able to use it automatically.)

## License

See [LICENSE](./LICENSE) file.
