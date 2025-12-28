# Subscription Guide

This guide provides detailed information about how subscriptions work in the Propaganda API.

## Overview

The Propaganda API supports a tiered subscription model with four levels:
- **None** - Free tier
- **Basic** - $4.99/month or $54.00/year
- **Plus** - $9.99/month or $108.00/year
- **Premium** - $14.99/month or $162.00/year

## Subscription Plans

### Available Plans

| Plan ID | Name | Monthly | Annual | Benefits |
|---------|------|---------|--------|----------|
| 34809bc1-28e5-4967-b029-2432638b0dc7 | basic | $4.99 | $54.00 | Basic features |
| 375af719-c9e0-44c4-be05-4527df45a13d | plus | $9.99 | $108.00 | Plus features |
| dd339fda-33e9-49d0-9eb5-0ccb77eb760f | premium | $14.99 | $162.00 | Premium features |

### Plan Benefits

#### None (Free)
- Access to free articles only
- Full ad experience
- Standard support

#### Basic
- Access to basic articles
- Reduced ads
- Priority support
- Email newsletter

#### Plus
- All Basic benefits
- Access to plus articles
- Minimal ads
- Early access to articles
- Comment participation

#### Premium
- All Plus benefits
- Full premium content access
- Ad-free experience
- Exclusive content
- 24/7 premium support

## Subscription Data Models

### Subscription Model

Location: `lib/src/data/models/subscription.dart`

```dart
@JsonSerializable(explicitToJson: true)
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.benefits,
  });

  final String id;
  final SubscriptionPlan name;
  final SubscriptionCost cost;
  final List<String> benefits;
}
```

### Subscription Plan Enum

```dart
enum SubscriptionPlan {
  none,
  basic,
  plus,
  premium,
}
```

### Subscription Cost Model

```dart
@JsonSerializable()
class SubscriptionCost extends Equatable {
  const SubscriptionCost({required this.monthly, required this.annual});

  final int monthly;  // in cents
  final int annual;   // in cents
}
```

## Subscription API Endpoints

### Get Available Subscriptions

**Endpoint:** `GET /api/v1/subscriptions`

**Description:** Returns all available subscription plans.

**Request:**
```http
GET /api/v1/subscriptions
```

**Response (200 OK):**
```json
{
  "subscriptions": [
    {
      "id": "dd339fda-33e9-49d0-9eb5-0ccb77eb760f",
      "name": "premium",
      "cost": {
        "monthly": 1499,
        "annual": 16200
      },
      "benefits": [
        "No ads",
        "Access to premium content",
        "Unlimited reads"
      ]
    },
    {
      "id": "375af719-c9e0-44c4-be05-4527df45a13d",
      "name": "plus",
      "cost": {
        "monthly": 999,
        "annual": 10800
      },
      "benefits": [
        "Reduced ads",
        "Priority support"
      ]
    },
    {
      "id": "34809bc1-28e5-4967-b029-2432638b0dc7",
      "name": "basic",
      "cost": {
        "monthly": 499,
        "annual": 5400
      },
      "benefits": [
        "Basic features"
      ]
    }
  ]
}
```

### Create Subscription

**Endpoint:** `POST /api/v1/subscriptions?subscriptionId={subscription-id}`

**Description:** Creates a subscription for the authenticated user.

**Request:**
```http
POST /api/v1/subscriptions?subscriptionId=dd339fda-33e9-49d0-9eb5-0ccb77eb760f
Authorization: Bearer user123
```

**Response (201 Created):**
```http
HTTP/1.1 201 Created
```

**Error Responses:**

- **400 Bad Request** - Missing subscriptionId or anonymous user
```http
HTTP/1.1 400 Bad Request
```

### Get Current User Subscription

**Endpoint:** `GET /api/v1/users/me`

**Description:** Returns the current user's information including subscription status.

**Request:**
```http
GET /api/v1/users/me
Authorization: Bearer user123
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "user123",
    "subscription": "premium"
  }
}
```

**Response for user with no subscription:**
```json
{
  "user": {
    "id": "user456",
    "subscription": "none"
  }
}
```

## Subscription Implementation

### Data Source Implementation

The `InMemoryNewsDataSource` manages subscription storage:

```dart
class InMemoryNewsDataSource implements NewsDataSource {
  InMemoryNewsDataSource() : _userSubscriptions = <String, String>{};

  final Map<String, String> _userSubscriptions;

  @override
  Future<void> createSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    final subscriptionPlan = subscriptions
        .firstWhereOrNull((subscription) => subscription.id == subscriptionId)
        ?.name;

    if (subscriptionPlan != null) {
      _userSubscriptions[userId] = subscriptionPlan.name;
    }
  }
}
```

### Route Handler Implementation

The subscription endpoint handler at `routes/api/v1/subscriptions/index.dart`:

```dart
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _onPostRequest(context);
  }
  if (context.request.method == HttpMethod.get) {
    return _onGetRequest(context);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _onPostRequest(RequestContext context) async {
  final subscriptionId = context.request.url.queryParameters['subscriptionId'];
  final user = context.read<RequestUser>();

  if (user.isAnonymous || subscriptionId == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  await context.read<NewsDataSource>().createSubscription(
        userId: user.id,
        subscriptionId: subscriptionId,
      );

  return Response(statusCode: HttpStatus.created);
}

Future<Response> _onGetRequest(RequestContext context) async {
  final subscriptions = await context.read<NewsDataSource>().getSubscriptions();
  final response = SubscriptionsResponse(subscriptions: subscriptions);
  return Response.json(body: response);
}
```

### User Subscription Retrieval

```dart
@override
Future<User> getUser({required String userId}) async {
  final subscription = _userSubscriptions[userId];
  if (subscription == null) {
    return User(id: userId, subscription: SubscriptionPlan.none);
  }
  return User(
    id: userId,
    subscription: SubscriptionPlan.values.firstWhere(
      (e) => e.name == subscription,
    ),
  );
}
```

## Subscription Workflow

### 1. User Registration

1. User registers with the application (handled by client)
2. User receives user ID
3. User can now authenticate with the API

### 2. Browse Subscription Plans

1. Client calls `GET /api/v1/subscriptions`
2. API returns all available plans with pricing and benefits
3. User selects a plan

### 3. Create Subscription

1. User selects a plan from the list
2. Client calls `POST /api/v1/subscriptions?subscriptionId={plan-id}`
3. API validates the plan ID exists
4. API stores the user's subscription
5. API returns 201 Created

### 4. Access Premium Content

1. User requests premium article
2. API checks article's `isPremium` flag
3. API checks user's subscription tier
4. If user has valid subscription, return full content
5. Otherwise, return preview only

## Subscription Use Cases

### Use Case 1: New User

```bash
# User registers and receives user ID: user123

# Browse available subscriptions
curl http://localhost:8080/api/v1/subscriptions

# Select premium plan
curl -X POST "http://localhost:8080/api/v1/subscriptions?subscriptionId=dd339fda-33e9-49d0-9eb5-0ccb77eb760f" \
  -H "Authorization: Bearer user123"

# Verify subscription
curl http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer user123"
```

### Use Case 2: Upgrade Subscription

```bash
# Current user has basic subscription

# Upgrade to premium
curl -X POST "http://localhost:8080/api/v1/subscriptions?subscriptionId=dd339fda-33e9-49d0-9eb5-0ccb77eb760f" \
  -H "Authorization: Bearer user123"

# Verify upgrade
curl http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer user123"
```

### Use Case 3: Downgrade Subscription

```bash
# Current user has premium subscription

# Downgrade to basic
curl -X POST "http://localhost:8080/api/v1/subscriptions?subscriptionId=34809bc1-28e5-4967-b029-2432638b0dc7" \
  -H "Authorization: Bearer user123"

# Verify downgrade
curl http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer user123"
```

## Subscription and Content Access

### Content Access Rules

```dart
Future<bool> canAccessContent({
  required bool isPremiumContent,
  required User? user,
}) {
  // Free content - everyone can access
  if (!isPremiumContent) return true;

  // Premium content - requires valid subscription
  if (user == null) return false;
  if (user.subscription == SubscriptionPlan.none) return false;

  return true;
}
```

### Subscription Tier Benefits Matrix

| Feature | None | Basic | Plus | Premium |
|---------|------|-------|------|---------|
| Free Articles | ✓ | ✓ | ✓ | ✓ |
| Basic Articles | ✗ | ✓ | ✓ | ✓ |
| Plus Articles | ✗ | ✗ | ✓ | ✓ |
| Premium Articles | ✗ | ✗ | ✗ | ✓ |
| Full Ads | ✓ | ✓ | ✓ | ✗ |
| Reduced Ads | ✗ | ✓ | ✓ | ✗ |
| Minimal Ads | ✗ | ✗ | ✓ | ✗ |
| Ad-Free | ✗ | ✗ | ✗ | ✓ |

## Subscription Management

### Adding a New Subscription Plan

1. Add the subscription to `lib/src/data/static_news_data.dart`:

```dart
const subscriptions = <Subscription>[
  Subscription(
    id: 'new-plan-id',
    name: SubscriptionPlan.newPlan,
    cost: SubscriptionCost(
      annual: 12000,
      monthly: 999,
    ),
    benefits: [
      'Benefit 1',
      'Benefit 2',
    ],
  ),
  // ... existing subscriptions
];
```

2. Add the plan to the `SubscriptionPlan` enum:

```dart
enum SubscriptionPlan {
  none,
  basic,
  plus,
  premium,
  newPlan,  // Add here
}
```

3. Update API documentation

4. Update pricing and benefits matrix

### Modifying Subscription Benefits

Edit the benefits list in `static_news_data.dart`:

```dart
Subscription(
  id: 'dd339fda-33e9-49d0-9eb5-0ccb77eb760f',
  name: SubscriptionPlan.premium,
  cost: SubscriptionCost(
    annual: 16200,
    monthly: 1499,
  ),
  benefits: [
    'No ads',
    'Access to premium content',
    'Unlimited reads',
    'Exclusive content',  // Add new benefit
    'Priority support',   // Add new benefit
  ],
),
```

## Testing Subscriptions

### Test Getting Subscriptions

```bash
curl http://localhost:8080/api/v1/subscriptions
```

### Test Creating Subscription

```bash
curl -X POST "http://localhost:8080/api/v1/subscriptions?subscriptionId=dd339fda-33e9-49d0-9eb5-0ccb77eb760f" \
  -H "Authorization: Bearer test-user"
```

### Test Getting User Subscription

```bash
curl http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer test-user"
```

### Test Anonymous Access

```bash
# This should return 400 Bad Request
curl http://localhost:8080/api/v1/users/me
```

## Production Considerations

### Payment Integration

In production, subscription creation should integrate with payment providers:

```dart
Future<Response> _onPostRequest(RequestContext context) async {
  final subscriptionId = context.request.url.queryParameters['subscriptionId'];
  final user = context.read<RequestUser>();

  if (user.isAnonymous || subscriptionId == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  // Verify payment with payment provider
  final paymentVerified = await _verifyPayment(
    userId: user.id,
    subscriptionId: subscriptionId,
  );

  if (!paymentVerified) {
    return Response(statusCode: HttpStatus.paymentRequired);
  }

  await context.read<NewsDataSource>().createSubscription(
        userId: user.id,
        subscriptionId: subscriptionId,
      );

  return Response(statusCode: HttpStatus.created);
}
```

### Subscription Renewal

Implement automatic subscription renewal:

```dart
Future<void> renewSubscriptions() async {
  final expiredSubscriptions = await _getExpiringSubscriptions();

  for (final user in expiredSubscriptions) {
    final renewed = await _renewSubscription(user.id);

    if (!renewed) {
      await _cancelSubscription(user.id);
    }
  }
}
```

### Subscription Analytics

Track subscription metrics:

```dart
class SubscriptionAnalytics {
  int totalSubscriptions;
  int activeSubscriptions;
  Map<SubscriptionPlan, int> subscriptionsByPlan;
  double averageRevenuePerUser;
}
```

## Summary

- Four subscription tiers: none, basic, plus, premium
- Subscription information stored in user profile
- Premium content access requires valid subscription
- Subscriptions affect ad display
- Integration with payment providers needed for production
