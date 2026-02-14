Local runbook for CTF Exchange
Steps to start

- Start dependencies: database, message queue, cache.

- Run migrations (if provided).

- Start the exchange service.

Verifications

- curl http://localhost:<port>/health returns OK.

- Logs show successful DB connections.

Common issues

- Port conflicts: stop other services or change ports.

- DB auth errors: verify credentials in .env.local.

- Stale data: reset local volumes and restart.

Use this checklist before digging into code.
