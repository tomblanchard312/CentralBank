# CentralBank API Gateway

REST API gateway for the CentralBank Digital Token Protocol. The gateway integrates institutions with the generic DigitalToken contract and associated wallet, policy, and conditional-payment services. Jurisdictional denomination and policy belong to the selected deployment profile.

## Features

- **Wallet Management**: Register, activate/deactivate wallets with KYC compliance
- **Token Operations**: Mint, burn, and transfer CBDT with configured holding-limit enforcement
- **Waterfall/Reverse-Waterfall**: Automatic excess sweeping to linked settlement accounts
- **Conditional Payments**: Escrow with delivery confirmation, time-locks, disputes
- **Role-Based Access Control**: Central-bank, registrar, issuer, PSP, bank, and merchant permissions
- **Audit Logging**: Regulatory and operational audit events
- **Rate Limiting**: Per-institution rate limiting
- **Idempotency**: Duplicate request handling for financial safety

## Quick Start

### Prerequisites

- Node.js 20+
- npm
- Running Besu node (or use Docker Compose)
- Deployed CentralBank smart contracts

### Installation

```bash
npm ci
cp .env.example .env
# Edit .env with your contract addresses and configuration
```

### Development

```bash
npm run dev
```

### Production

```bash
npm run build
npm start
```

### Docker

```bash
docker-compose up -d
docker-compose logs -f api
```

## API Documentation

Interactive API documentation is available at `http://localhost:3000/api/docs`.

## API Endpoints

### Health

- `GET /api/v1/health` - Full health check
- `GET /api/v1/health/ready` - Readiness probe
- `GET /api/v1/health/live` - Liveness probe

### Wallets

- `POST /api/v1/wallets` - Register new wallet
- `GET /api/v1/wallets/:address` - Get wallet info
- `GET /api/v1/wallets/:address/balance` - Get balance
- `POST /api/v1/wallets/:address/deactivate` - Deactivate wallet
- `POST /api/v1/wallets/:address/reactivate` - Reactivate wallet
- `PUT /api/v1/wallets/:address/linked-bank` - Update linked settlement account

### Transfers

- `POST /api/v1/transfers` - Transfer CBDT using payer-signed authorization
- `POST /api/v1/transfers/mint` - Request authorized CBDT issuance
- `POST /api/v1/transfers/burn` - Request authorized CBDT redemption/burn
- `POST /api/v1/transfers/waterfall` - Execute waterfall
- `POST /api/v1/transfers/reverse-waterfall` - Execute reverse waterfall
- `GET /api/v1/transfers/balance/:address` - Get balance
- `GET /api/v1/transfers/total-supply` - Get total supply

### Conditional Payments

- `POST /api/v1/payments` - Create conditional payment
- `GET /api/v1/payments/:paymentId` - Get payment details
- `POST /api/v1/payments/:paymentId/confirm-delivery` - Confirm delivery
- `POST /api/v1/payments/:paymentId/release` - Release payment
- `POST /api/v1/payments/:paymentId/cancel` - Cancel payment
- `POST /api/v1/payments/:paymentId/dispute` - Dispute payment
- `POST /api/v1/payments/:paymentId/resolve` - Resolve dispute

### Admin

- `GET /api/v1/admin/system/status` - System status
- `POST /api/v1/admin/system/pause` - Pause operations
- `POST /api/v1/admin/system/unpause` - Resume operations
- `POST /api/v1/admin/roles/grant` - Grant role
- `POST /api/v1/admin/roles/revoke` - Revoke role
- `GET /api/v1/admin/roles/check` - Check role
- `GET /api/v1/admin/roles/available` - List roles

## Authentication

### API Key

```bash
curl -X GET "http://localhost:3000/api/v1/wallets/0x..." \
  -H "X-API-Key: demo-bank-key"
```

### Bearer Token (JWT)

```bash
curl -X GET "http://localhost:3000/api/v1/wallets/0x..." \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

## Demo API Keys

Development fixtures include representative institutional keys. They are test-only credentials and must not be used in production.

## Environment Variables

| Variable                          | Description                          | Default               |
| --------------------------------- | ------------------------------------ | --------------------- |
| `PORT`                            | Server port                          | 3000                  |
| `NODE_ENV`                        | Environment                          | development           |
| `BLOCKCHAIN_RPC_URL`              | Besu RPC endpoint                    | http://localhost:8545 |
| `BLOCKCHAIN_CHAIN_ID`             | Chain ID                             | 31337                 |
| `BLOCKCHAIN_OPERATOR_PRIVATE_KEY` | Development/test operator signing key | -                    |
| `CONTRACT_PERMISSIONING`          | Permissioning contract address       | -                     |
| `CONTRACT_WALLET_REGISTRY`        | WalletRegistry contract address      | -                     |
| `CONTRACT_DIGITAL_TOKEN`          | DigitalToken contract address        | -                     |
| `CONTRACT_CONDITIONAL_PAYMENTS`   | ConditionalPayments contract address | -                     |
| `JWT_SECRET`                      | JWT signing secret                   | -                     |
| `RATE_LIMIT_WINDOW_MS`            | Rate limit window                    | 60000                 |
| `RATE_LIMIT_MAX`                  | Max requests per window              | 100                   |
| `CORS_ORIGIN`                     | Allowed CORS origins                 | `*`                   |
| `LOG_LEVEL`                       | Logging level                        | info                  |

## Amounts

Amounts use the token's configured minor-unit precision. For the `eurosystem-reference` profile, CBDT is denominated in EUR with two decimal places, so `100` represents EUR 1.00.

Holding limits and other numeric monetary-policy values are profile/policy configuration, not properties of the generic CBDT identity.

## Idempotency

Write operations support idempotency keys where defined by the route and contract operation.

```json
{
  "to": "0x...",
  "amount": 100000,
  "idempotencyKey": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Error Responses

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [],
    "requestId": "abc-123"
  }
}
```

| Code                   | HTTP | Description                        |
| ---------------------- | ---- | ---------------------------------- |
| `VALIDATION_ERROR`     | 400  | Invalid request data               |
| `AUTHENTICATION_ERROR` | 401  | Missing/invalid credentials        |
| `AUTHORIZATION_ERROR`  | 403  | Insufficient permissions           |
| `NOT_FOUND`            | 404  | Resource not found                 |
| `CONFLICT`             | 409  | Duplicate or conflicting operation |
| `RATE_LIMIT_EXCEEDED`  | 429  | Too many requests                  |
| `BLOCKCHAIN_ERROR`     | 502  | Smart contract error               |
| `INTERNAL_ERROR`       | 500  | Unexpected server error            |

## Audit Logging

Operations are recorded with actor/institution identity, action, resource, timestamp, outcome, and relevant request metadata. Production-grade durable append-only audit persistence remains a separate hardening requirement.

## Security

- Authenticated protected endpoints
- Per-institution authorization
- Rate limiting
- Zod request validation
- Helmet security headers
- CORS configuration
- Non-root Docker user
- Payer-signed transaction relay for economic-custody operations
- Production local-key signing is rejected pending KMS/HSM integration

## Positioning

CentralBank is an independent open-source reference implementation. The `eurosystem-reference` profile is informed by published Eurosystem concepts; the project is not issued, endorsed, sponsored, or operated by the ECB, Eurosystem, or any national central bank.
