# Authentication Guide

This guide provides detailed information about how authentication works in the Propaganda API.

## Overview

The Propaganda API uses a simple Bearer token authentication system. Users are identified by a user ID passed in the `Authorization` header.

## Authentication Flow

### 1. Middleware Processing

All requests pass through the `userProvider` middleware located at `lib/src/middleware/user_provider.dart`:

```dart
Middleware userProvider() {
  return (handler) {
    return handler.use(
      provider<RequestUser>((context) {
        final userId = _extractUserId(context.request);
        return userId != null
            ? RequestUser._(id: userId)
            : RequestUser.anonymous;
      }),
    );
  };
}
```

This middleware is applied in `routes/_middleware.dart`:

```dart
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(userProvider())
      .use(newsDataSourceProvider());
}
```

### 2. User ID Extraction

The `_extractUserId` function parses the `Authorization` header:

```dart
String? _extractUserId(Request request) {
  final authorizationHeader = request.headers['authorization'];
  if (authorizationHeader == null) return null;           // No auth header
  final segments = authorizationHeader.split(' ');
  if (segments.length != 2) return null;                 // Invalid format
  if (segments.first.toLowerCase() != 'bearer') return null;  // Not Bearer token
  final userId = segments.last;
  return userId;
}
```

### 3. RequestUser Object

The `RequestUser` class represents an authenticated or anonymous user:

```dart
class RequestUser {
  const RequestUser._({required this.id});

  final String id;

  static const anonymous = RequestUser._(id: '');

  bool get isAnonymous => this == RequestUser.anonymous;
}
```

## Using Authentication in Routes

### Accessing the Authenticated User

Routes can access the authenticated user via the request context:

```dart
final reqUser = context.read<RequestUser>();

if (reqUser.isAnonymous) {
  return Response(statusCode: HttpStatus.badRequest);
}

final user = await context.read<NewsDataSource>()
    .getUser(userId: reqUser.id);
```

### Example: Get Current User

```dart
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final reqUser = context.read<RequestUser>();
  if (reqUser.isAnonymous) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  final user = await context.read<NewsDataSource>()
      .getUser(userId: reqUser.id);

  if (user == null) {
    return Response(statusCode: HttpStatus.notFound);
  }

  final response = CurrentUserResponse(user: user);
  return Response.json(body: response);
}
```

## Authentication Scenarios

### Scenario 1: Authenticated Request

**Request:**
```http
GET /api/v1/users/me
Authorization: Bearer user123
```

**Processing:**
1. Middleware extracts `user123` from Authorization header
2. Creates `RequestUser(id: 'user123')`
3. Route handler reads `RequestUser` from context
4. Retrieves user data from data source
5. Returns user information

**Response:**
```json
{
  "user": {
    "id": "user123",
    "subscription": "premium"
  }
}
```

### Scenario 2: Anonymous Request to Protected Endpoint

**Request:**
```http
GET /api/v1/users/me
```

**Processing:**
1. Middleware finds no Authorization header
2. Creates `RequestUser.anonymous`
3. Route handler checks `isAnonymous`
4. Returns 400 Bad Request

**Response:**
```http
HTTP/1.1 400 Bad Request
```

### Scenario 3: Invalid Authorization Header

**Request:**
```http
GET /api/v1/users/me
Authorization: InvalidToken user123
```

**Processing:**
1. Middleware finds Authorization header
2. Parses header: `['InvalidToken', 'user123']`
3. First segment is not 'bearer' → returns null
4. Creates `RequestUser.anonymous`
5. Route handler checks `isAnonymous`
6. Returns 400 Bad Request

**Response:**
```http
HTTP/1.1 400 Bad Request
```

## Authentication in Premium Content Access

Authentication is used to determine if a user can access premium content:

```dart
Future<bool> shouldShowFullArticle() async {
  if (previewRequested) return false;
  if (!isPremium) return true;

  final requestUser = context.read<RequestUser>();

  // Anonymous users cannot access premium content
  if (isPremium && requestUser.isAnonymous) return false;

  // Get user's subscription
  final user = await newsDataSource.getUser(userId: requestUser.id);
  if (user == null) return false;

  // Users with no subscription cannot access premium content
  if (user.subscription == SubscriptionPlan.none) return false;

  return true;
}
```

## Best Practices

### 1. Always Check for Anonymous Users

```dart
final reqUser = context.read<RequestUser>();
if (reqUser.isAnonymous) {
  return Response(statusCode: HttpStatus.unauthorized);
}
```

### 2. Handle Missing Users

```dart
final user = await context.read<NewsDataSource>()
    .getUser(userId: reqUser.id);
if (user == null) {
  return Response(statusCode: HttpStatus.notFound);
}
```

### 3. Use Consistent Error Codes

- `400 Bad Request` - Invalid request or anonymous access to protected endpoint
- `401 Unauthorized` - Missing or invalid authentication
- `404 Not Found` - User not found

### 4. Document Authentication Requirements

All endpoints that require authentication should document this requirement:

```http
GET /api/v1/users/me

Headers:
Authorization: Bearer {user-id} (required)

Response 200: User data
Response 400: Unauthorized (anonymous)
Response 404: User not found
```

## Security Considerations

### Current Implementation

The current implementation uses a simple Bearer token where the token is the user ID. This is suitable for development and demonstration purposes.

### Production Considerations

For production use, consider:

1. **JWT Tokens**: Use JSON Web Tokens with expiration and signing
2. **Token Refresh**: Implement token refresh mechanism
3. **Rate Limiting**: Add rate limiting to prevent abuse
4. **HTTPS Only**: Always use HTTPS in production
5. **Token Validation**: Add token validation with signature verification

### Example JWT Implementation

```dart
String? _extractUserId(Request request) {
  final authorizationHeader = request.headers['authorization'];
  if (authorizationHeader == null) return null;

  final segments = authorizationHeader.split(' ');
  if (segments.length != 2) return null;
  if (segments.first.toLowerCase() != 'bearer') return null;

  final token = segments.last;
  return _validateJwtToken(token);
}

String? _validateJwtToken(String token) {
  try {
    final payload = jwt.verify(token, secretKey);
    return payload['userId'] as String?;
  } catch (e) {
    return null;
  }
}
```

## Testing Authentication

### Test with Valid Token

```bash
curl -H "Authorization: Bearer user123" \
  http://localhost:8080/api/v1/users/me
```

### Test with Invalid Token

```bash
curl -H "Authorization: Bearer invalid" \
  http://localhost:8080/api/v1/users/me
```

### Test without Authentication

```bash
curl http://localhost:8080/api/v1/users/me
```

## Summary

- Authentication uses Bearer tokens with user IDs
- Middleware extracts and provides `RequestUser` to all routes
- Anonymous users cannot access protected endpoints
- Premium content access requires authentication + valid subscription
- Production implementations should use JWT tokens
