# Propaganda API Documentation

Welcome to the Propaganda API documentation. This API is a news platform built with Dart using the Dart Frog framework.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Subscriptions](#subscriptions)
- [Articles](#articles)
- [Ads](#ads)
- [Data Models](#data-models)
- [API Endpoints](#api-endpoints)

## Overview

The Propaganda API provides a comprehensive news platform with features including:

- News feed management with categories
- Article content with premium/free tier support
- User authentication and authorization
- Subscription management (basic, plus, premium)
- Ad integration (banner ads)
- Search functionality (popular and relevant)
- Newsletter subscriptions

### Tech Stack

- **Language**: Dart
- **Framework**: Dart Frog
- **Data Source**: In-memory data storage (for development)
- **Serialization**: json_annotation/json_serializable

## Authentication

### How Authentication Works

Authentication in the Propaganda API uses Bearer token authentication. The authentication flow works as follows:

#### Step 1: Authentication Middleware

The `userProvider()` middleware (`lib/src/middleware/user_provider.dart`) processes each incoming request:

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

#### Step 2: Extracting User ID

The `_extractUserId()` function extracts the user ID from the `Authorization` header:

```dart
String? _extractUserId(Request request) {
  final authorizationHeader = request.headers['authorization'];
  if (authorizationHeader == null) return null;
  final segments = authorizationHeader.split(' ');
  if (segments.length != 2) return null;
  if (segments.first.toLowerCase() != 'bearer') return null;
  final userId = segments.last;
  return userId;
}
```

#### Step 3: Request User Object

The `RequestUser` class represents an authenticated user:

```dart
class RequestUser {
  const RequestUser._({required this.id});

  final String id;

  static const anonymous = RequestUser._(id: '');

  bool get isAnonymous => this == RequestUser.anonymous;
}
```

#### Step 4: Using Authentication in Routes

Routes access the authenticated user via `context.read<RequestUser>()`:

```dart
final reqUser = context.read<RequestUser>();
if (reqUser.isAnonymous) {
  return Response(statusCode: HttpStatus.badRequest);
}
```

### Authentication Examples

#### Authenticated Request
```http
GET /api/v1/users/me
Authorization: Bearer user123
```

#### Anonymous Request
```http
GET /api/v1/users/me
```

### Authentication Flow Diagram

1. **Client Request** → API with `Authorization: Bearer <user-id>` header
2. **Middleware Processing** → userProvider extracts user ID
3. **RequestUser Creation** → RequestUser instance added to context
4. **Route Handler** → Accesses user via context.read<RequestUser>()
5. **Response** → Returns user-specific data or error if anonymous

## Subscriptions

### Subscription Plans

The API supports four subscription tiers:

1. **None** - No subscription (free tier)
2. **Basic** - $4.99/month or $54.00/year
3. **Plus** - $9.99/month or $108.00/year
4. **Premium** - $14.99/month or $162.00/year

### How Subscriptions Work

#### Step 1: User Subscription Model

The `User` model includes subscription information:

```dart
class User {
  final String id;
  final SubscriptionPlan subscription;
}
```

#### Step 2: Creating a Subscription

Users can create subscriptions via POST to `/api/v1/subscriptions`:

```dart
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
```

#### Step 3: Data Source Storage

The `InMemoryNewsDataSource` stores user subscriptions:

```dart
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
```

#### Step 4: Retrieving User Subscription

The API retrieves a user's subscription status:

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

### Subscription Benefits

Different subscription tiers provide different benefits:

| Plan | Features |
|------|----------|
| None | - Free articles<br>- Limited content access<br>- Ads shown |
| Basic | - Access to basic articles<br>- Fewer ads<br>- Standard support |
| Plus | - All Basic benefits<br>- Access to plus articles<br>- Priority support |
| Premium | - All Plus benefits<br>- Full premium content access<br>- Ad-free experience |

### Subscription API Endpoints

#### Get Available Subscriptions
```http
GET /api/v1/subscriptions
```

#### Create Subscription
```http
POST /api/v1/subscriptions?subscriptionId=<subscription-id>
Authorization: Bearer <user-id>
```

#### Get Current User
```http
GET /api/v1/users/me
Authorization: Bearer <user-id>
```

### Subscription Flow Diagram

1. **List Subscriptions** → Client calls GET /api/v1/subscriptions
2. **Select Plan** → User chooses a subscription plan
3. **Create Subscription** → POST /api/v1/subscriptions with subscriptionId
4. **Update User Record** → Data source stores user's subscription
5. **Verify Subscription** → Future requests check user's subscription tier

## Articles

### How Articles Work

#### Step 1: Article Data Model

Articles are represented by the `Article` model:

```dart
class Article {
  final String title;
  final List<NewsBlock> blocks;
  final int totalBlocks;
  final Uri url;
}
```

#### Step 2: NewsItem Structure

The `NewsItem` class combines post information with content:

```dart
class NewsItem {
  final List<NewsBlock> content;
  final List<NewsBlock> contentPreview;
  final PostBlock post;
  final Uri url;
  final List<NewsBlock> relatedArticles;
}
```

#### Step 3: Article Access Control

Articles can be marked as premium via the `isPremium` flag on post blocks:

```dart
class PostBlock {
  final bool isPremium;
}
```

#### Step 4: Article Access Logic

The API determines if a user can access full article content:

```dart
Future<bool> shouldShowFullArticle() async {
  if (previewRequested) return false;
  if (!isPremium) return true;
  final requestUser = context.read<RequestUser>();
  if (isPremium && requestUser.isAnonymous) return false;
  final user = await newsDataSource.getUser(userId: requestUser.id);
  if (user == null) return false;
  if (user.subscription == SubscriptionPlan.none) return false;
  return true;
}
```

### Article Access Rules

| Article Type | User Type | Access Level |
|--------------|-----------|--------------|
| Free | Anonymous | Preview only |
| Free | Authenticated (any tier) | Full content |
| Premium | Anonymous | Preview only |
| Premium | Authenticated (no subscription) | Preview only |
| Premium | Basic/Plus/Premium | Full content |

### Article API Endpoints

#### Get Article by ID
```http
GET /api/v1/articles/{id}?limit={limit}&offset={offset}&preview={true|false}
```

#### Get Related Articles
```http
GET /api/v1/articles/{id}/related?limit={limit}&offset={offset}
```

### Article Content Blocks

Articles are composed of various block types:

- **PostBlock** - Article metadata (title, author, image, etc.)
- **TextBlocks** - Text content (headline, paragraph, caption)
- **ImageBlock** - Images
- **VideoBlock** - Videos
- **SectionHeaderBlock** - Section headers
- **DividerHorizontalBlock** - Dividers
- **SpacerBlock** - Spacing
- **BannerAdBlock** - Advertisements

### Article Flow Diagram

1. **Request Article** → Client requests article by ID
2. **Check Premium Status** → API determines if article is premium
3. **Check User Subscription** → API verifies user's subscription tier
4. **Determine Access** → Decide whether to show full content or preview
5. **Return Content** → Return appropriate content blocks

## Ads

### How Ads Work

#### Step 1: Banner Ad Block Model

Ads are implemented as banner ad blocks:

```dart
class BannerAdBlock implements NewsBlock {
  static const identifier = '__banner_ad__';
  final BannerAdSize size;
  final String type;
}
```

#### Step 2: Ad Size Options

Banner ads support multiple sizes:

```dart
enum BannerAdSize {
  normal,      // Standard banner ad
  large,       // Large banner ad
  extraLarge,  // Extra large banner ad
  anchoredAdaptive  // Anchored adaptive banner
}
```

#### Step 3: Ad Integration

Ads are included in feed and article content as regular blocks:

```dart
final feed = [
  SectionHeaderBlock(title: 'Breaking News'),
  PostLargeBlock(...),
  BannerAdBlock(size: BannerAdSize.normal),  // Ad inserted
  PostMediumBlock(...),
];
```

#### Step 4: Ad Block Serialization

Banner ad blocks are serialized/deserialized like other blocks:

```dart
case BannerAdBlock.identifier:
  return BannerAdBlock.fromJson(json);
```

### Ad Placement Strategy

Ads are strategically placed in:

1. **News Feeds** - Every N blocks (configurable)
2. **Articles** - Between content sections
3. **Premium Articles** - Only shown to non-subscribers

### Ad vs Subscription

| User Type | Ad Display |
|-----------|------------|
| Anonymous | Full ad display |
| Authenticated (None) | Full ad display |
| Basic | Reduced ads |
| Plus | Minimal ads |
| Premium | No ads |

### Ad Block Examples

#### Standard Banner Ad
```json
{
  "type": "__banner_ad__",
  "size": "normal"
}
```

#### Large Banner Ad
```json
{
  "type": "__banner_ad__",
  "size": "large"
}
```

### Ad Flow Diagram

1. **Generate Content** → Create feed or article blocks
2. **Check User Subscription** → Determine user's tier
3. **Insert Ads** → Add BannerAdBlock instances based on tier
4. **Return Content** → Send blocks with ads to client
5. **Client Display** → Client renders ad blocks

## Data Models

### Core Data Models

#### User Model
Location: `lib/src/data/models/user.dart`

```dart
class User {
  final String id;
  final SubscriptionPlan subscription;
}
```

**Usage**:
- Returned by `GET /api/v1/users/me`
- Stored in data source mapped by user ID
- Used to determine access rights to premium content

#### Article Model
Location: `lib/src/data/models/article.dart`

```dart
class Article {
  final String title;
  final List<NewsBlock> blocks;
  final int totalBlocks;
  final Uri url;
}
```

**Usage**:
- Returned by `GET /api/v1/articles/{id}`
- Contains paginated content blocks
- Includes total block count for pagination

#### Subscription Model
Location: `lib/src/data/models/subscription.dart`

```dart
class Subscription {
  final String id;
  final SubscriptionPlan name;
  final SubscriptionCost cost;
  final List<String> benefits;
}

enum SubscriptionPlan {
  none,
  basic,
  plus,
  premium,
}

class SubscriptionCost {
  final int monthly;  // in cents
  final int annual;   // in cents
}
```

**Usage**:
- Returned by `GET /api/v1/subscriptions`
- Contains pricing and benefit information
- Used in subscription creation flow

#### NewsItem Model
Location: `lib/src/data/models/news_item.dart`

```dart
class NewsItem {
  final List<NewsBlock> content;
  final List<NewsBlock> contentPreview;
  final PostBlock post;
  final Uri url;
  final List<NewsBlock> relatedArticles;
}
```

**Usage**:
- Internal data structure for articles
- Contains full content and preview content
- Includes related articles

#### Feed Model
Location: `lib/src/data/models/feed.dart`

```dart
class Feed {
  final List<NewsBlock> blocks;
  final int totalBlocks;
}
```

**Usage**:
- Returned by `GET /api/v1/feed`
- Contains paginated feed blocks
- Includes total block count for pagination

### Response Models

#### ArticleResponse
Location: `lib/src/models/article_response/article_response.dart`

```dart
class ArticleResponse {
  final String title;
  final List<NewsBlock> content;
  final int totalCount;
  final Uri url;
  final bool isPremium;
  final bool isPreview;
}
```

#### FeedResponse
Location: `lib/src/models/feed_response/feed_response.dart`

```dart
class FeedResponse {
  final List<NewsBlock> feed;
  final int totalCount;
}
```

#### CurrentUserResponse
Location: `lib/src/models/current_user_response/current_user_response.dart`

```dart
class CurrentUserResponse {
  final User user;
}
```

#### SubscriptionsResponse
Location: `lib/src/models/subscriptions_response/subscriptions_response.dart`

```dart
class SubscriptionsResponse {
  final List<Subscription> subscriptions;
}
```

### Block Models (from news_blocks package)

All content is composed of blocks that implement the `NewsBlock` interface:

#### Content Blocks
- **PostBlock** (abstract) - Base for post-type blocks
  - **PostLargeBlock** - Large article preview
  - **PostMediumBlock** - Medium article preview
  - **PostSmallBlock** - Small article preview
  - **PostGridTileBlock** - Grid tile article preview

- **PostGridGroupBlock** - Group of grid tiles

#### Text Blocks
- **TextHeadlineBlock** - Headline text
- **TextLeadParagraphBlock** - Lead paragraph
- **TextParagraphBlock** - Regular paragraph
- **TextCaptionBlock** - Caption text

#### Media Blocks
- **ImageBlock** - Image
- **VideoBlock** - Video
- **VideoIntroductionBlock** - Video introduction

#### Layout Blocks
- **SectionHeaderBlock** - Section header
- **DividerHorizontalBlock** - Horizontal divider
- **SpacerBlock** - Spacing

#### Special Blocks
- **BannerAdBlock** - Advertisement
- **NewsletterBlock** - Newsletter signup
- **ArticleIntroductionBlock** - Article introduction
- **TrendingStoryBlock** - Trending story
- **SlideshowBlock** - Slideshow
- **SlideBlock** - Slide
- **SlideshowIntroductionBlock** - Slideshow introduction
- **HtmlBlock** - HTML content
- **UnknownBlock** - Unknown block type

### Data Model Relationships

```
User
  └── SubscriptionPlan (enum)

Subscription
  ├── SubscriptionPlan (enum)
  └── SubscriptionCost

Article
  ├── List<NewsBlock>
  └── PostBlock (from NewsItem)

NewsItem
  ├── List<NewsBlock> (content)
  ├── List<NewsBlock> (contentPreview)
  ├── PostBlock (post)
  └── List<NewsBlock> (relatedArticles)

Feed
  └── List<NewsBlock>

NewsBlock (interface)
  ├── PostBlock (abstract)
  │   ├── PostLargeBlock
  │   ├── PostMediumBlock
  │   └── PostSmallBlock
  ├── TextHeadlineBlock
  ├── TextParagraphBlock
  ├── ImageBlock
  ├── VideoBlock
  ├── BannerAdBlock
  └── ... (other block types)
```

### Serialization

All models use JSON serialization via `json_annotation` and `json_serializable`:

```dart
@JsonSerializable()
class Article {
  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleToJson(this);
}
```

Run `dart run build_runner build` to generate serialization code.

## API Endpoints

### Base URL
```
http://localhost:8080
```

### Health Check
```http
GET /
Response: 204 No Content
```

### Articles

#### Get Article
```http
GET /api/v1/articles/{id}?limit={limit}&offset={offset}&preview={true|false}

Parameters:
- id (required): Article ID
- limit (optional): Number of blocks to return (default: 20)
- offset (optional): Zero-based offset (default: 0)
- preview (optional): Return preview content (default: false)

Response 200:
{
  "title": "Article Title",
  "content": [...],
  "totalCount": 42,
  "url": "https://example.com/article",
  "isPremium": false,
  "isPreview": false
}
```

#### Get Related Articles
```http
GET /api/v1/articles/{id}/related?limit={limit}&offset={offset}

Parameters:
- id (required): Article ID
- limit (optional): Number of blocks to return (default: 20)
- offset (optional): Zero-based offset (default: 0)

Response 200:
{
  "related_articles": [...],
  "total_count": 10
}
```

### Categories

#### Get Categories
```http
GET /api/v1/categories

Response 200:
{
  "categories": ["business", "entertainment", "general", "health", "science", "sports", "technology"]
}
```

### Feed

#### Get Feed
```http
GET /api/v1/feed?category={category}&limit={limit}&offset={offset}

Parameters:
- category (optional): Feed category (default: general)
- limit (optional): Number of blocks to return (default: 20)
- offset (optional): Zero-based offset (default: 0)

Response 200:
{
  "feed": [...],
  "total_count": 100
}
```

### Newsletter

#### Subscribe to Newsletter
```http
POST /api/v1/newsletter/subscription

Body:
{
  "email": "user@example.com"
}

Response 201: Created
```

### Search

#### Popular Search
```http
GET /api/v1/search/popular

Response 200:
{
  "topics": ["Ukraine", "Supreme Court", "China"],
  "articles": [...]
}
```

#### Relevant Search
```http
GET /api/v1/search/relevant?q={query}

Parameters:
- q (required): Search query

Response 200:
{
  "topics": ["Topic 1", "Topic 2"],
  "articles": [...]
}
```

### Subscriptions

#### Get Subscriptions
```http
GET /api/v1/subscriptions

Response 200:
{
  "subscriptions": [
    {
      "id": "uuid",
      "name": "premium",
      "cost": {
        "monthly": 1499,
        "annual": 16200
      },
      "benefits": ["No ads", "Premium content", "Unlimited reads"]
    }
  ]
}
```

#### Create Subscription
```http
POST /api/v1/subscriptions?subscriptionId={subscription-id}

Headers:
Authorization: Bearer {user-id}

Response 201: Created
```

### Users

#### Get Current User
```http
GET /api/v1/users/me

Headers:
Authorization: Bearer {user-id}

Response 200:
{
  "user": {
    "id": "user-id",
    "subscription": "premium"
  }
}
```

## Development

### Running the Server
```bash
dart_frog dev
```

### Building for Production
```bash
dart_frog build
cd build
docker build -t propaganda-api .
```

### Running Tests
```bash
dart test
```

### Generating Serialization Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Request Flow

1. **Incoming Request** → API endpoint
2. **Middleware Chain** → Request logging → User provider → Data source provider
3. **Route Handler** → Process request
4. **Data Source** → Retrieve/update data
5. **Response** → Return JSON response

### Middleware Stack

1. **requestLogger** - Logs all requests
2. **userProvider** - Extracts and provides authenticated user
3. **newsDataSourceProvider** - Provides in-memory data source

### Data Layer

- **NewsDataSource** (interface) - Defines data operations
- **InMemoryNewsDataSource** (implementation) - In-memory storage

### Model Layer

- **Data Models** - Internal data structures
- **Response Models** - API response structures
- **Block Models** - Content blocks (from news_blocks package)

## Contributing

When adding new features:

1. Create/update data models in `lib/src/data/models/`
2. Create/update response models in `lib/src/models/`
3. Implement data source methods in `lib/src/data/`
4. Create route handlers in `routes/api/v1/`
5. Update API documentation in `docs/api.apib`
6. Write tests in `test/`

## License

See project repository for license information.
