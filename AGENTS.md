# ModuleX Project Notes

## Infrastructure

- The production host is the AWS Lightsail instance at `3.34.50.251`.
- Public DNS for `modules-x.com` is managed in the Lightsail console under
  `Domains & DNS > modules-x.com > DNS records`.
- Do not add application subdomains to the similarly named Route 53 hosted
  zone; that zone is not delegated for public `modules-x.com` traffic.
- Active Docker Compose sites:
  - `modulex-demo` -> host port `8080`
  - `builder-hc` -> host port `8082`
  - `enterprise-demo` -> host port `8084`
- Nginx on the Lightsail host terminates HTTPS and proxies each subdomain to
  its corresponding local Docker port.

