# Database Migration Guidelines

When evolving the CTF exchange database schema, follow these steps:

## Planning

- Document all schema changes and review with the team.
- Avoid destructive operations; prefer additive changes.
- Assign a unique, sequential version number to each migration.

## Creating a migration

1. Create a new SQL file in `migrations/` with a descriptive name.
2. Write `UP` statements to apply the change.
3. Write corresponding `DOWN` statements to revert the change.
4. Update the migration index or registry as needed.

## Applying migrations

- Use the provided migration tool (e.g. `sqlx migrate run`).
- Always run migrations in a staging environment first.
- Monitor for errors and roll back if necessary.

Clear migration practices help maintain data integrity and simplify rollbacks.
