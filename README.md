# Creative Collective

[![CI](https://github.com/Sereza111/creative_collective/actions/workflows/ci.yml/badge.svg)](https://github.com/Sereza111/creative_collective/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js)](https://nodejs.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Full-stack freelance marketplace for clients, freelancers, and platform administrators. The project combines a Flutter application with an Express/MySQL API and covers the workflow from publishing an order to selecting a contractor, communicating, reviewing the result, and resolving disputes.

> Project status: portfolio-ready alpha. The core marketplace flows are implemented, but production payments, real-time delivery, and deployment hardening are still required before commercial use.

## What is implemented

| Area | Capabilities |
| --- | --- |
| Marketplace | Orders, filtering, applications, contractor selection, favorites |
| Collaboration | Chats, project and task management, notifications |
| Reputation | Freelancer profiles, portfolios, ratings, reviews |
| Operations | Admin panel, user verification, disputes, moderation |
| Finance prototype | Internal balances, transaction ledger, withdrawal requests |
| Platform | JWT authentication, role-based access, rate limiting, migrations, Docker |

The finance module is an internal ledger prototype. It does not process real card or bank payments yet.

## Architecture

```text
Flutter app (Riverpod)
        |
        | REST / JWT
        v
Express API
        |
        +-- MySQL 8
        +-- local upload storage
        +-- scheduled background jobs
```

The repository contains:

- `lib/` - Flutter UI, providers, models, and API client;
- `backend/src/` - Express routes, controllers, middleware, and jobs;
- `backend/src/database/` - baseline schema and migration runner;
- `backend/migrations_uuid/` - ordered marketplace migrations;
- `site/` - web deployment configuration;
- `.github/workflows/ci.yml` - backend and Flutter verification.

## Local setup

### Prerequisites

- Flutter 3.19 or newer
- Node.js 18 or newer
- MySQL 8

### Backend

```bash
cd backend
cp .env.example .env
npm ci
npm run migrate
npm start
```

Set the database connection and replace both JWT secrets in `backend/.env` before starting the API. The migration command applies `backend/src/database/schema.sql` and the ordered migrations from `backend/migrations_uuid/`.

API health endpoints:

- `GET http://localhost:3000/`
- `GET http://localhost:3000/health`

### Flutter

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

For a release web build:

```bash
flutter build web --release --dart-define=API_BASE_URL=/api/v1
```

## Verification

```bash
# Backend
cd backend
npm test
npm audit --omit=dev --audit-level=high

# Flutter (from the repository root)
flutter test
flutter build web --release --dart-define=API_BASE_URL=/api/v1
```

GitHub Actions runs these checks for every pull request and every push to `main`.

## Security notes

- Public registration can create only `client` and `freelancer` accounts.
- Administrative accounts must be provisioned through an operator-controlled workflow.
- Compose configurations require explicit database and JWT secrets.
- Configure `CORS_ORIGIN` and `TRUST_PROXY_HOPS` for the deployment environment.

Do not use development secrets or wildcard CORS settings in production.

## Roadmap to SaaS

- Integrate a payment provider with webhooks and idempotent operations.
- Add end-to-end tests against MySQL for the order and finance lifecycles.
- Introduce WebSocket or managed real-time delivery for chat and notifications.
- Move uploads to object storage and add malware/type validation.
- Add observability, backups, recovery drills, and deployment documentation.
- Complete legal, privacy, moderation, and payout compliance for the target market.

## License

Released under the [MIT License](LICENSE).
