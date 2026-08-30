# Authentication observability

`prometheus/authentication-alerts.yml` is a Prometheus-compatible rule file for
Phase 3 account-security monitoring. Configure the Prometheus server to load this
file through its `rule_files` setting, and route `severity=critical` alerts to the
security on-call path.

Validate the rule contract locally:

```shell
uv run --with PyYAML python scripts/check_authentication_alert_rules.py
uv run --with PyYAML python -m unittest tests.test_check_authentication_alert_rules -v
```

Validate PromQL with a pinned Prometheus release when `promtool` is not installed:

```shell
docker run --rm --entrypoint promtool \
  -v "$PWD/ops/observability/prometheus:/rules:ro" \
  prom/prometheus:v3.5.0 check rules /rules/authentication-alerts.yml
```

The rule file is intentionally independent of a particular deployment mechanism.
Deployments must preserve the global `application=speakeasy-backend` metric tag and
enable the `http.server.requests` percentile histogram before loading the latency
alert. Required metric names and label constraints are listed in the authentication
runbook.
