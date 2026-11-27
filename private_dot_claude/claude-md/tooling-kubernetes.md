### Kubernetes

| Scenario | Cluster | Use | `kubectl` | MCP |
| --- | --- | --- | --- | --- |
| Reads | `homelab` | MCP | no access | yes (except secrets) |
| Reads | `nas` | MCP | no access | yes (except secrets) |
| Reads | `sandbox-talos` | either | yes (except secrets) | yes (except secrets) |
| Writes | `homelab` | not allowed | no access | no access |
| Writes | `nas` | not allowed | no access | no access |
| Writes | `sandbox-talos` | either | yes (incl. secrets) | yes (incl. secrets) |

Metrics (Prometheus) and logs (Loki) are queryable via the Grafana MCP.
