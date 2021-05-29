# Kind Scratchpad

A place to experiment with [kind] and [kubernetes].

## Usage

```
$ make help
```

## Dependencies

The ingress functionality relies on subdomains of `kind` resolving to `127.0.0.1`.
[dnsmasq] enables this functionality.

[kind]:https://kind.sigs.k8s.io
[kubernetes]:https://kubernetes.io
[dnmasq]:https://thekelleys.org.uk/dnsmasq/doc.html
