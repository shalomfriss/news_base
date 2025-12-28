# Data Models Guide

This guide provides comprehensive information about all data models used in the Propaganda API, including their structure, relationships, and usage patterns.

## Overview

The Propaganda API uses a layered data model architecture:
- **Data Models** - Internal domain models
- **Response Models** - API response wrappers
- **Block Models** - Content composition blocks (from news_blocks package)

## Data Models

### User Model

**Location:** `lib/src/data/models/user.dart`

**Purpose:** Represents a user in the system.

**Structure:**
```dart
@JsonSerializable(explicitToJson: true)
class User extends Equatable {
  const User({required this.id, required this.subscription});

  final String id;                           // User identifier
  final SubscriptionPlan subscription;          // Subscription tier

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

**Usage:**
- Returned by `GET /api/v1/users/me`
- Stored in data source mapped by user ID
- Used to determine access rights to premium content

**Example JSON:**
```json
{
  "id": "user123",
  "subscription": "premium"
}
```

### Article Model

**Location:** `lib/src/data/models/article.dart`

**Purpose:** Represents a news article with paginated content.

**Structure:**
```dart
@JsonSerializable()
class Article extends Equatable {
  const Article({
    required this.title,
    required this.blocks,
    required this.totalBlocks,
    required this.url,
  });

  final String title;                        // Article title
  @NewsBlocksConverter()
  final List<NewsBlock> blocks;             // Content blocks (paginated)
  final int totalBlocks;                     // Total block count
  final Uri url;                            // Article URL

  factory Article.fromJson(Map<String, dynamic> json) => _$ArticleFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleToJson(this);
}
```

**Usage:**
- Internal model for article data
- Contains paginated content blocks
- Returned by `GET /api/v1/articles/{id}`

**Example JSON:**
```json
{
  "title": "Breaking News",
  "blocks": [...],
  "totalBlocks": 42,
  "url": "https://example.com/article"
}
```

### NewsItem Model

**Location:** `lib/src/data/models/news_item.dart`

**Purpose:** Combines article metadata with content and related articles.

**Structure:**
```dart
class NewsItem {
  const NewsItem({
    required this.content,
    required this.contentPreview,
    required this.post,
    required this.url,
    this.relatedArticles = const [],
  });

  final List<NewsBlock> content;            // Full article content
  final List<NewsBlock> contentPreview;      // Article preview content
  final PostBlock post;                      // Post metadata for feed
  final Uri url;                            // Article URL
  final List<NewsBlock> relatedArticles;      // Related article blocks
}
```

**Usage:**
- Internal data structure for articles
- Contains full content and preview content
- Includes related articles
- Used by data source to build article responses

### Feed Model

**Location:** `lib/src/data/models/feed.dart`

**Purpose:** Represents a news feed with paginated blocks.

**Structure:**
```dart
@JsonSerializable()
class Feed extends Equatable {
  const Feed({required this.blocks, required this.totalBlocks});

  @NewsBlocksConverter()
  final List<NewsBlock> blocks;             // Feed blocks (paginated)
  final int totalBlocks;                     // Total block count

  factory Feed.fromJson(Map<String, dynamic> json) => _$FeedFromJson(json);
  Map<String, dynamic> toJson() => _$FeedToJson(this);
}
```

**Usage:**
- Returned by `GET /api/v1/feed`
- Contains paginated feed blocks
- Includes total block count for pagination

**Example JSON:**
```json
{
  "blocks": [...],
  "totalBlocks": 100
}
```

### Subscription Model

**Location:** `lib/src/data/models/subscription.dart`

**Purpose:** Represents a subscription plan with pricing and benefits.

**Structure:**
```dart
@JsonSerializable(explicitToJson: true)
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.benefits,
  });

  final String id;                           // Subscription ID
  final SubscriptionPlan name;                // Plan name
  final SubscriptionCost cost;                // Cost information
  final List<String> benefits;               // List of benefits

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}
```

**Usage:**
- Returned by `GET /api/v1/subscriptions`
- Used in subscription creation flow
- Contains pricing and benefit information

**Example JSON:**
```json
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
}
```

### SubscriptionPlan Enum

**Purpose:** Defines available subscription tiers.

**Structure:**
```dart
enum SubscriptionPlan {
  none,      // No subscription
  basic,     // Basic subscription
  plus,      // Plus subscription
  premium,    // Premium subscription
}
```

**Usage:**
- Used in User model
- Used in Subscription model
- Determines content access rights

### SubscriptionCost Model

**Location:** `lib/src/data/models/subscription.dart`

**Purpose:** Represents subscription pricing.

**Structure:**
```dart
@JsonSerializable()
class SubscriptionCost extends Equatable {
  const SubscriptionCost({required this.monthly, required this.annual});

  final int monthly;    // Monthly cost in cents
  final int annual;     // Annual cost in cents

  factory SubscriptionCost.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionCostFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionCostToJson(this);
}
```

**Usage:**
- Nested in Subscription model
- Costs stored in cents to avoid floating-point issues

**Example JSON:**
```json
{
  "monthly": 1499,    // $14.99
  "annual": 16200     // $162.00
}
```

### RelatedArticles Model

**Location:** `lib/src/data/models/related_articles.dart`

**Purpose:** Represents related articles for a given article.

**Structure:**
```dart
@JsonSerializable()
class RelatedArticles extends Equatable {
  const RelatedArticles({required this.blocks, required this.totalBlocks});

  @NewsBlocksConverter()
  final List<NewsBlock> blocks;             // Related article blocks
  final int totalBlocks;                     // Total block count

  factory RelatedArticles.fromJson(Map<String, dynamic> json) =>
      _$RelatedArticlesFromJson(json);
  Map<String, dynamic> toJson() => _$RelatedArticlesToJson(this);

  const RelatedArticles.empty()
      : blocks = const [],
        totalBlocks = 0;
}
```

**Usage:**
- Returned by `GET /api/v1/articles/{id}/related`
- Contains paginated related articles
- Includes total block count

**Example JSON:**
```json
{
  "blocks": [...],
  "totalBlocks": 10
}
```

## Response Models

### ArticleResponse

**Location:** `lib/src/models/article_response/article_response.dart`

**Purpose:** Wraps article data for API responses.

**Structure:**
```dart
@JsonSerializable()
class ArticleResponse extends Equatable {
  const ArticleResponse({
    required this.title,
    required this.content,
    required this.totalCount,
    required this.url,
    required this.isPremium,
    required this.isPreview,
  });

  final String title;                        // Article title
  @NewsBlocksConverter()
  final List<NewsBlock> content;            // Content blocks
  final int totalCount;                     // Total block count
  final Uri url;                            // Article URL
  final bool isPremium;                      // Premium flag
  final bool isPreview;                      // Preview flag

  factory ArticleResponse.fromJson(Map<String, dynamic> json) =>
      _$ArticleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/articles/{id}`
- Includes premium/preview status
- Adds metadata beyond the base Article model

**Example JSON:**
```json
{
  "title": "Article Title",
  "content": [...],
  "totalCount": 42,
  "url": "https://example.com/article",
  "isPremium": false,
  "isPreview": false
}
```

### FeedResponse

**Location:** `lib/src/models/feed_response/feed_response.dart`

**Purpose:** Wraps feed data for API responses.

**Structure:**
```dart
@JsonSerializable()
class FeedResponse extends Equatable {
  const FeedResponse({required this.feed, required this.totalCount});

  @NewsBlocksConverter()
  final List<NewsBlock> feed;               // Feed blocks
  final int totalCount;                       // Total block count

  factory FeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FeedResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/feed`
- Wraps Feed model for API consistency

**Example JSON:**
```json
{
  "feed": [...],
  "totalCount": 100
}
```

### CurrentUserResponse

**Location:** `lib/src/models/current_user_response/current_user_response.dart`

**Purpose:** Wraps user data for API responses.

**Structure:**
```dart
@JsonSerializable(explicitToJson: true)
class CurrentUserResponse extends Equatable {
  const CurrentUserResponse({required this.user});

  final User user;                            // User object

  factory CurrentUserResponse.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentUserResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/users/me`
- Wraps User model for API consistency

**Example JSON:**
```json
{
  "user": {
    "id": "user123",
    "subscription": "premium"
  }
}
```

### SubscriptionsResponse

**Location:** `lib/src/models/subscriptions_response/subscriptions_response.dart`

**Purpose:** Wraps subscription list for API responses.

**Structure:**
```dart
@JsonSerializable(explicitToJson: true)
class SubscriptionsResponse extends Equatable {
  const SubscriptionsResponse({required this.subscriptions});

  final List<Subscription> subscriptions;      // Subscription list

  factory SubscriptionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubscriptionsResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/subscriptions`
- Wraps subscription list for API consistency

**Example JSON:**
```json
{
  "subscriptions": [...]
}
```

### CategoriesResponse

**Location:** `lib/src/models/categories_response/categories_response.dart`

**Purpose:** Wraps categories list for API responses.

**Structure:**
```dart
@JsonSerializable()
class CategoriesResponse extends Equatable {
  const CategoriesResponse({required this.categories});

  final List<Category> categories;               // Category list

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$CategoriesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CategoriesResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/categories`
- Wraps category list for API consistency

**Example JSON:**
```json
{
  "categories": ["business", "technology", "sports"]
}
```

### PopularSearchResponse

**Location:** `lib/src/models/popular_search_response/popular_search_response.dart`

**Purpose:** Wraps popular search results for API responses.

**Structure:**
```dart
@JsonSerializable()
class PopularSearchResponse extends Equatable {
  const PopularSearchResponse({
    required this.topics,
    required this.articles,
  });

  final List<String> topics;                   // Popular topics
  @NewsBlocksConverter()
  final List<NewsBlock> articles;             // Popular articles

  factory PopularSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$PopularSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PopularSearchResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/search/popular`
- Contains trending topics and articles

**Example JSON:**
```json
{
  "topics": ["Ukraine", "Supreme Court", "China"],
  "articles": [...]
}
```

### RelevantSearchResponse

**Location:** `lib/src/models/relevant_search_response/relevant_search_response.dart`

**Purpose:** Wraps relevant search results for API responses.

**Structure:**
```dart
@JsonSerializable()
class RelevantSearchResponse extends Equatable {
  const RelevantSearchResponse({
    required this.topics,
    required this.articles,
  });

  final List<String> topics;                   // Relevant topics
  @NewsBlocksConverter()
  final List<NewsBlock> articles;             // Relevant articles

  factory RelevantSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$RelevantSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RelevantSearchResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/search/relevant`
- Contains search results based on query

**Example JSON:**
```json
{
  "topics": ["Topic 1", "Topic 2"],
  "articles": [...]
}
```

### RelatedArticlesResponse

**Location:** `lib/src/models/related_articles_response/related_articles_response.dart`

**Purpose:** Wraps related articles for API responses.

**Structure:**
```dart
@JsonSerializable()
class RelatedArticlesResponse extends Equatable {
  const RelatedArticlesResponse({
    required this.relatedArticles,
    required this.totalCount,
  });

  @NewsBlocksConverter()
  final List<NewsBlock> relatedArticles;       // Related article blocks
  final int totalCount;                       // Total block count

  factory RelatedArticlesResponse.fromJson(Map<String, dynamic> json) =>
      _$RelatedArticlesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RelatedArticlesResponseToJson(this);
}
```

**Usage:**
- Response for `GET /api/v1/articles/{id}/related`
- Wraps RelatedArticles model for API consistency

**Example JSON:**
```json
{
  "related_articles": [...],
  "totalCount": 10
}
```

## Block Models (from news_blocks package)

All content is composed of blocks that implement the `NewsBlock` interface:

### NewsBlock Interface

**Location:** `packages/news_blocks/lib/src/news_block.dart`

**Purpose:** Base interface for all content blocks.

**Structure:**
```dart
@JsonSerializable()
abstract class NewsBlock {
  const NewsBlock({required this.type});

  final String type;                           // Block type identifier

  Map<String, dynamic> toJson();

  static NewsBlock fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case SectionHeaderBlock.identifier:
        return SectionHeaderBlock.fromJson(json);
      case BannerAdBlock.identifier:
        return BannerAdBlock.fromJson(json);
      // ... other block types
    }
    return const UnknownBlock();
  }
}
```

**Usage:**
- Base type for all content blocks
- Provides deserialization logic
- Client can render any NewsBlock implementation

### PostBlock (Abstract)

**Location:** `packages/news_blocks/lib/src/post_block.dart`

**Purpose:** Base class for post-type blocks (article previews in feeds).

**Structure:**
```dart
abstract class PostBlock with EquatableMixin implements NewsBlock {
  const PostBlock({
    required this.id,
    required this.category,
    required this.author,
    required this.publishedAt,
    required this.title,
    required this.type,
    this.imageUrl,
    this.description,
    this.action,
    this.isPremium = false,
    this.isContentOverlaid = false,
  });

  final String id;                           // Article ID
  final PostCategory category;                // Category
  final String author;                       // Author name
  final DateTime publishedAt;                 // Publication date
  final String? imageUrl;                    // Image URL
  final String title;                        // Title
  final String? description;                 // Description
  final BlockAction? action;                 // Navigation action
  final bool isPremium;                      // Premium flag
  final bool isContentOverlaid;             // Content overlay flag
  final String type;                         // Block type
}
```

**Usage:**
- Base for article preview blocks in feeds
- Contains article metadata
- Supports navigation actions

**Implementations:**
- `PostLargeBlock` - Large article preview
- `PostMediumBlock` - Medium article preview
- `PostSmallBlock` - Small article preview
- `PostGridTileBlock` - Grid tile article preview

### Content Blocks

#### SectionHeaderBlock

**Purpose:** Section headers in feeds and articles.

**Structure:**
```dart
{
  "type": "__section_header__",
  "title": "Breaking News"
}
```

#### DividerHorizontalBlock

**Purpose:** Horizontal dividers between content.

**Structure:**
```json
{
  "type": "__divider_horizontal__"
}
```

#### SpacerBlock

**Purpose:** Adds spacing between elements.

**Structure:**
```json
{
  "type": "__spacer__",
  "spacing": "medium"
}
```

#### ArticleIntroductionBlock

**Purpose:** Introduction block for articles.

**Structure:**
```json
{
  "type": "__article_introduction__",
  "category": "technology",
  "author": "John Doe",
  "publishedAt": "2022-03-17T00:00:00.000",
  "imageUrl": "https://example.com/image.jpg",
  "title": "Article Title"
}
```

### Text Blocks

#### TextHeadlineBlock

**Purpose:** Headline text.

**Structure:**
```json
{
  "type": "__text_headline__",
  "content": "Breaking News"
}
```

#### TextLeadParagraphBlock

**Purpose:** Lead paragraph text.

**Structure:**
```json
{
  "type": "__text_lead_paragraph__",
  "content": "Lead paragraph..."
}
```

#### TextParagraphBlock

**Purpose:** Regular paragraph text.

**Structure:**
```json
{
  "type": "__text_paragraph__",
  "content": "Paragraph content..."
}
```

#### TextCaptionBlock

**Purpose:** Caption for images or media.

**Structure:**
```json
{
  "type": "__text_caption__",
  "content": "Image caption"
}
```

### Media Blocks

#### ImageBlock

**Purpose:** Images in articles and feeds.

**Structure:**
```json
{
  "type": "__image__",
  "url": "https://example.com/image.jpg",
  "caption": "Image caption"
}
```

#### VideoBlock

**Purpose:** Videos in articles.

**Structure:**
```json
{
  "type": "__video__",
  "url": "https://example.com/video.mp4",
  "thumbnailUrl": "https://example.com/thumbnail.jpg",
  "duration": 120
}
```

#### VideoIntroductionBlock

**Purpose:** Video introduction block.

**Structure:**
```json
{
  "type": "__video_intro__",
  "title": "Video Title",
  "url": "https://example.com/video.mp4",
  "thumbnailUrl": "https://example.com/thumbnail.jpg",
  "duration": 120
}
```

### Special Blocks

#### BannerAdBlock

**Purpose:** Advertisement banners.

**Structure:**
```json
{
  "type": "__banner_ad__",
  "size": "normal"
}
```

#### NewsletterBlock

**Purpose:** Newsletter subscription prompt.

**Structure:**
```json
{
  "type": "__newsletter__",
  "text": "Subscribe to our newsletter",
  "action": {
    "type": "navigate_to_newsletter",
    "url": "https://example.com/newsletter"
  }
}
```

#### TrendingStoryBlock

**Purpose:** Trending story highlight.

**Structure:**
```json
{
  "type": "__trending_story__",
  "title": "Trending Story",
  "action": {
    "type": "navigate_to_article",
    "articleId": "article-id"
  }
}
```

#### SlideshowBlock

**Purpose:** Slideshow content.

**Structure:**
```json
{
  "type": "__slideshow__",
  "slides": [
    {
      "type": "__slide__",
      "url": "https://example.com/slide1.jpg",
      "caption": "Slide 1"
    }
  ]
}
```

#### HtmlBlock

**Purpose:** HTML content.

**Structure:**
```json
{
  "type": "__html__",
  "html": "<p>HTML content</p>"
}
```

#### UnknownBlock

**Purpose:** Fallback for unrecognized block types.

**Structure:**
```json
{
  "type": "__unknown__"
}
```

## Model Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                     Response Models                      │
├─────────────────────────────────────────────────────────────┤
│ ArticleResponse     │  FeedResponse                    │
│  └─ Article         │  └─ Feed                        │
│                      │    └─ List<NewsBlock>            │
│ CurrentUserResponse  │                                  │
│  └─ User            │  SubscriptionsResponse            │
│   └─ SubscriptionPlan│  └─ List<Subscription>           │
│                      │    └─ Subscription               │
│ PopularSearchResponse│     └─ SubscriptionCost          │
│  ├─ List<String>    │                                  │
│  └─ List<NewsBlock>│  RelatedArticlesResponse          │
│                      │  └─ RelatedArticles              │
│ RelatedArticlesResponse│   └─ List<NewsBlock>            │
│  └─ RelatedArticles  │                                  │
│   └─ List<NewsBlock>│  CategoriesResponse              │
└──────────────────────┘  └─ List<Category>              │
┌─────────────────────────────────────────────────────────────┐
│                      Data Models                        │
├─────────────────────────────────────────────────────────────┤
│ User               │  Article                          │
│  └─ SubscriptionPlan│  └─ List<NewsBlock>              │
│                      │                                  │
│ NewsItem           │  Feed                             │
│  ├─ PostBlock       │  └─ List<NewsBlock>              │
│  ├─ List<NewsBlock>│                                  │
│  ├─ List<NewsBlock>│  Subscription                     │
│  └─ Uri             │  └─ SubscriptionPlan              │
└──────────────────────┘  └─ SubscriptionCost             │
┌─────────────────────────────────────────────────────────────┐
│                     Block Models                        │
├─────────────────────────────────────────────────────────────┤
│ NewsBlock (interface)                                   │
│  ├─ PostBlock (abstract)                                │
│  │  ├─ PostLargeBlock                                   │
│  │  ├─ PostMediumBlock                                  │
│  │  └─ PostSmallBlock                                   │
│  ├─ TextBlocks                                         │
│  │  ├─ TextHeadlineBlock                                │
│  │  ├─ TextLeadParagraphBlock                            │
│  │  ├─ TextParagraphBlock                               │
│  │  └─ TextCaptionBlock                                 │
│  ├─ MediaBlocks                                        │
│  │  ├─ ImageBlock                                      │
│  │  ├─ VideoBlock                                      │
│  │  └─ VideoIntroductionBlock                            │
│  ├─ LayoutBlocks                                       │
│  │  ├─ SectionHeaderBlock                               │
│  │  ├─ DividerHorizontalBlock                            │
│  │  └─ SpacerBlock                                     │
│  ├─ SpecialBlocks                                      │
│  │  ├─ BannerAdBlock                                   │
│  │  ├─ NewsletterBlock                                  │
│  │  ├─ TrendingStoryBlock                               │
│  │  └─ HtmlBlock                                       │
│  └─ UnknownBlock                                        │
└─────────────────────────────────────────────────────────────┘
```

## Model Usage Patterns

### Creating New Models

1. **Define Data Model** (if needed):

```dart
@JsonSerializable()
class MyModel extends Equatable {
  const MyModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
  Map<String, dynamic> toJson() => _$MyModelToJson(this);
}
```

2. **Define Response Model**:

```dart
@JsonSerializable()
class MyModelResponse extends Equatable {
  const MyModelResponse({required this.data});

  final MyModel data;

  factory MyModelResponse.fromJson(Map<String, dynamic> json) =>
      _$MyModelResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyModelResponseToJson(this);
}
```

3. **Generate Serialization Code**:

```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Implement in Data Source**:

```dart
@override
Future<MyModel> getMyModel({required String id}) async {
  // Implementation
}
```

5. **Create Route Handler**:

```dart
Future<Response> onRequest(RequestContext context, String id) async {
  final myModel = await context.read<NewsDataSource>()
      .getMyModel(id: id);

  final response = MyModelResponse(data: myModel);
  return Response.json(body: response);
}
```

### Extending Existing Models

1. **Add New Field**:

```dart
@JsonSerializable()
class Article extends Equatable {
  const Article({
    required this.title,
    required this.blocks,
    required this.totalBlocks,
    required this.url,
    this.author,  // New field
  });

  final String title;
  final List<NewsBlock> blocks;
  final int totalBlocks;
  final Uri url;
  final String? author;  // New field
}
```

2. **Regenerate Serialization Code**:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Model Validation

Models use `Equatable` for value equality:

```dart
final user1 = User(id: '123', subscription: SubscriptionPlan.premium);
final user2 = User(id: '123', subscription: SubscriptionPlan.premium);

print(user1 == user2);  // true
```

## Serialization

All models support JSON serialization via `json_annotation` and `json_serializable`.

### Enabling Serialization

1. Add `@JsonSerializable()` annotation:

```dart
@JsonSerializable()
class MyModel {
  const MyModel({required this.id});

  final String id;
}
```

2. Add factory constructor and method:

```dart
factory MyModel.fromJson(Map<String, dynamic> json) =>
    _$MyModelFromJson(json);

Map<String, dynamic> toJson() => _$MyModelToJson(this);
```

3. Add part directive:

```dart
part 'my_model.g.dart';
```

4. Generate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Custom Serialization

Use converters for complex types:

```dart
@NewsBlocksConverter()
final List<NewsBlock> blocks;
```

## Summary

- **Data Models** - Internal domain models (User, Article, Feed, Subscription)
- **Response Models** - API response wrappers (ArticleResponse, FeedResponse, etc.)
- **Block Models** - Content blocks from news_blocks package
- All models support JSON serialization
- Models use Equatable for value equality
- Use build_runner to generate serialization code
