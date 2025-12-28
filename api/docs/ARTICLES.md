# Articles Guide

This guide provides detailed information about how articles work in the Propaganda API.

## Overview

Articles in the Propaganda API are composed of content blocks that provide flexibility in rendering various types of news content. Articles can be free or premium, with premium content requiring a valid subscription.

## Article Data Models

### Article Model

Location: `lib/src/data/models/article.dart`

```dart
@JsonSerializable()
class Article extends Equatable {
  const Article({
    required this.title,
    required this.blocks,
    required this.totalBlocks,
    required this.url,
  });

  final String title;
  @NewsBlocksConverter()
  final List<NewsBlock> blocks;
  final int totalBlocks;
  final Uri url;
}
```

### NewsItem Model

Location: `lib/src/data/models/news_item.dart`

```dart
class NewsItem {
  const NewsItem({
    required this.content,
    required this.contentPreview,
    required this.post,
    required this.url,
    this.relatedArticles = const [],
  });

  final List<NewsBlock> content;
  final List<NewsBlock> contentPreview;
  final PostBlock post;
  final Uri url;
  final List<NewsBlock> relatedArticles;
}
```

### PostBlock Model

Location: `packages/news_blocks/lib/src/post_block.dart`

```dart
abstract class PostBlock implements NewsBlock {
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

  final String id;
  final PostCategory category;
  final String author;
  final DateTime publishedAt;
  final String? imageUrl;
  final String title;
  final String? description;
  final BlockAction? action;
  final bool isPremium;  // Premium flag
  final bool isContentOverlaid;
  final String type;
}
```

## Article API Endpoints

### Get Article by ID

**Endpoint:** `GET /api/v1/articles/{id}`

**Description:** Retrieves article content. Supports pagination and preview mode.

**Query Parameters:**
- `limit` (optional, number) - Number of blocks to return (default: 20)
- `offset` (optional, number) - Zero-based offset (default: 0)
- `preview` (optional, boolean) - Return preview content (default: false)

**Request:**
```http
GET /api/v1/articles/article-id-123
```

**Request with pagination:**
```http
GET /api/v1/articles/article-id-123?limit=10&offset=20
```

**Request for preview:**
```http
GET /api/v1/articles/article-id-123?preview=true
```

**Response (200 OK):**
```json
{
  "title": "Article Title",
  "content": [
    {
      "type": "__article_introduction__",
      "category": "technology",
      "author": "John Doe",
      "publishedAt": "2022-03-17T00:00:00.000",
      "imageUrl": "https://example.com/image.jpg",
      "title": "Article Title"
    },
    {
      "type": "__text_paragraph__",
      "content": "This is the article content..."
    },
    {
      "type": "__image__",
      "url": "https://example.com/article-image.jpg"
    }
  ],
  "totalCount": 42,
  "url": "https://example.com/article",
  "isPremium": false,
  "isPreview": false
}
```

**Response for Premium Article (Preview):**
```json
{
  "title": "Premium Article Title",
  "content": [
    {
      "type": "__article_introduction__",
      "category": "technology",
      "author": "John Doe",
      "publishedAt": "2022-03-17T00:00:00.000",
      "imageUrl": "https://example.com/image.jpg",
      "title": "Premium Article Title"
    }
  ],
  "totalCount": 5,
  "url": "https://example.com/premium-article",
  "isPremium": true,
  "isPreview": true
}
```

**Error Responses:**

- **404 Not Found** - Article doesn't exist
```http
HTTP/1.1 404 Not Found
```

### Get Related Articles

**Endpoint:** `GET /api/v1/articles/{id}/related`

**Description:** Retrieves articles related to the specified article.

**Query Parameters:**
- `limit` (optional, number) - Number of blocks to return (default: 20)
- `offset` (optional, number) - Zero-based offset (default: 0)

**Request:**
```http
GET /api/v1/articles/article-id-123/related
```

**Response (200 OK):**
```json
{
  "related_articles": [
    {
      "id": "related-article-1",
      "category": "technology",
      "author": "Jane Smith",
      "publishedAt": "2022-03-18T00:00:00.000",
      "imageUrl": "https://example.com/related1.jpg",
      "title": "Related Article 1",
      "description": "A brief description...",
      "isPremium": false,
      "type": "__post_small__"
    },
    {
      "id": "related-article-2",
      "category": "technology",
      "author": "Bob Johnson",
      "publishedAt": "2022-03-19T00:00:00.000",
      "imageUrl": "https://example.com/related2.jpg",
      "title": "Related Article 2",
      "description": "Another description...",
      "isPremium": true,
      "type": "__post_small__"
    }
  ],
  "total_count": 10
}
```

## Article Access Control

### Access Logic

The API determines article access based on multiple factors:

```dart
Future<bool> shouldShowFullArticle() async {
  // 1. Explicitly requested preview
  if (previewRequested) return false;

  // 2. Free content - always accessible
  if (!isPremium) return true;

  // 3. Premium content - check user authentication
  final requestUser = context.read<RequestUser>();
  if (isPremium && requestUser.isAnonymous) return false;

  // 4. Premium content - check user subscription
  final user = await newsDataSource.getUser(userId: requestUser.id);
  if (user == null) return false;

  // 5. No subscription - cannot access premium content
  if (user.subscription == SubscriptionPlan.none) return false;

  // 6. Valid subscription - can access premium content
  return true;
}
```

### Access Decision Matrix

| Article Type | User Type | Subscription | Access Level |
|--------------|-----------|--------------|--------------|
| Free | Anonymous | N/A | Full content |
| Free | Authenticated | Any | Full content |
| Premium | Anonymous | N/A | Preview only |
| Premium | Authenticated | None | Preview only |
| Premium | Authenticated | Basic | Full content |
| Premium | Authenticated | Plus | Full content |
| Premium | Authenticated | Premium | Full content |

### Article Access Implementation

Location: `routes/api/v1/articles/[id]/index.dart`

```dart
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final queryParams = context.request.url.queryParameters;
  final limit = int.tryParse(queryParams['limit'] ?? '') ?? 20;
  final offset = int.tryParse(queryParams['offset'] ?? '') ?? 0;
  final previewRequested = queryParams['preview'] == 'true';
  final newsDataSource = context.read<NewsDataSource>();

  // Check if article is premium
  final isPremium = await newsDataSource.isPremiumArticle(id: id);

  if (isPremium == null) return Response(statusCode: HttpStatus.notFound);

  // Determine if user can access full content
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

  final showFullArticle = await shouldShowFullArticle();

  // Get article (preview if not full access)
  final article = await newsDataSource.getArticle(
    id: id,
    limit: limit,
    offset: offset,
    preview: !showFullArticle,
  );

  if (article == null) return Response(statusCode: HttpStatus.notFound);

  final response = ArticleResponse(
    title: article.title,
    content: article.blocks,
    totalCount: article.totalBlocks,
    url: article.url,
    isPremium: isPremium,
    isPreview: !showFullArticle,
  );

  return Response.json(body: response);
}
```

## Article Content Blocks

### Block Types

Articles are composed of various block types that implement the `NewsBlock` interface:

#### Article Introduction Block
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

#### Text Blocks

**Text Headline Block:**
```json
{
  "type": "__text_headline__",
  "content": "Breaking News"
}
```

**Text Lead Paragraph Block:**
```json
{
  "type": "__text_lead_paragraph__",
  "content": "This is the lead paragraph..."
}
```

**Text Paragraph Block:**
```json
{
  "type": "__text_paragraph__",
  "content": "This is a regular paragraph..."
}
```

**Text Caption Block:**
```json
{
  "type": "__text_caption__",
  "content": "Caption for image or media"
}
```

#### Media Blocks

**Image Block:**
```json
{
  "type": "__image__",
  "url": "https://example.com/image.jpg",
  "caption": "Image caption"
}
```

**Video Block:**
```json
{
  "type": "__video__",
  "url": "https://example.com/video.mp4",
  "thumbnailUrl": "https://example.com/thumbnail.jpg",
  "duration": 120
}
```

**Video Introduction Block:**
```json
{
  "type": "__video_intro__",
  "title": "Video Title",
  "url": "https://example.com/video.mp4",
  "thumbnailUrl": "https://example.com/thumbnail.jpg",
  "duration": 120
}
```

#### Layout Blocks

**Section Header Block:**
```json
{
  "type": "__section_header__",
  "title": "Section Title"
}
```

**Divider Horizontal Block:**
```json
{
  "type": "__divider_horizontal__"
}
```

**Spacer Block:**
```json
{
  "type": "__spacer__",
  "spacing": "medium"
}
```

#### Special Blocks

**Banner Ad Block:**
```json
{
  "type": "__banner_ad__",
  "size": "normal"
}
```

**Newsletter Block:**
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

**Trending Story Block:**
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

**Slideshow Block:**
```json
{
  "type": "__slideshow__",
  "slides": [
    {
      "type": "__slide__",
      "url": "https://example.com/slide1.jpg",
      "caption": "Slide 1"
    },
    {
      "type": "__slide__",
      "url": "https://example.com/slide2.jpg",
      "caption": "Slide 2"
    }
  ]
}
```

**Slideshow Introduction Block:**
```json
{
  "type": "__slideshow_introduction__",
  "title": "Slideshow Title",
  "subtitle": "Slideshow subtitle",
  "thumbnailUrl": "https://example.com/thumbnail.jpg"
}
```

**Html Block:**
```json
{
  "type": "__html__",
  "html": "<p>HTML content</p>"
}
```

## Article Categories

### Available Categories

- `business` - Business news
- `entertainment` - Entertainment news
- `top` - Top/breaking news
- `health` - Health news
- `science` - Science news
- `sports` - Sports news
- `technology` - Technology news

## Article Pagination

Articles support pagination to handle large content:

### Pagination Parameters

- `limit` - Number of blocks to return per page
- `offset` - Zero-based offset for the starting block

### Pagination Example

**Page 1:**
```http
GET /api/v1/articles/article-id-123?limit=20&offset=0
```

**Page 2:**
```http
GET /api/v1/articles/article-id-123?limit=20&offset=20
```

**Page 3:**
```http
GET /api/v1/articles/article-id-123?limit=20&offset=40
```

### Pagination Response

```json
{
  "title": "Article Title",
  "content": [...],  // 20 blocks
  "totalCount": 100,  // Total number of blocks
  "url": "https://example.com/article",
  "isPremium": false,
  "isPreview": false
}
```

## Article Workflow

### 1. Browse Articles

```bash
# Get feed
curl http://localhost:8080/api/v1/feed

# Get articles by category
curl http://localhost:8080/api/v1/feed?category=technology
```

### 2. View Free Article

```bash
# User can access free article without authentication
curl http://localhost:8080/api/v1/articles/free-article-id
```

### 3. View Premium Article (Anonymous)

```bash
# Anonymous user gets preview only
curl http://localhost:8080/api/v1/articles/premium-article-id

# Response contains preview and isPreview: true
```

### 4. View Premium Article (Authenticated, No Subscription)

```bash
# Authenticated user without subscription gets preview only
curl http://localhost:8080/api/v1/articles/premium-article-id \
  -H "Authorization: Bearer user123"

# Response contains preview and isPreview: true
```

### 5. View Premium Article (Authenticated, With Subscription)

```bash
# User with subscription gets full content
curl http://localhost:8080/api/v1/articles/premium-article-id \
  -H "Authorization: Bearer premium-user"

# Response contains full content and isPreview: false
```

### 6. Preview Mode

```bash
# Explicitly request preview
curl "http://localhost:8080/api/v1/articles/premium-article-id?preview=true" \
  -H "Authorization: Bearer premium-user"

# Response contains preview and isPreview: true
```

### 7. Get Related Articles

```bash
curl http://localhost:8080/api/v1/articles/article-id/related
```

## Article Use Cases

### Use Case 1: Infinite Scroll

Client implements infinite scroll for article content:

```dart
Future<void> loadMoreContent() async {
  final response = await http.get(
    Uri.parse(
      'http://localhost:8080/api/v1/articles/$articleId'
      '?limit=20&offset=${blocks.length}'
    ),
  );

  final data = jsonDecode(response.body);
  setState(() {
    blocks.addAll(data['content']);
  });
}
```

### Use Case 2: Premium Content Preview

Show premium article preview with upgrade prompt:

```dart
Widget buildArticle(BuildContext context, ArticleResponse response) {
  if (response.isPreview) {
    return Column(
      children: [
        ArticleContent(blocks: response.content),
        PremiumPrompt(),
      ],
    );
  }
  return ArticleContent(blocks: response.content);
}
```

### Use Case 3: Article Caching

Cache article content for offline reading:

```dart
Future<void> cacheArticle(String articleId) async {
  final response = await http.get(
    Uri.parse('http://localhost:8080/api/v1/articles/$articleId'),
  );

  await cacheManager.put(articleId, response.body);
}
```

## Article Data Source Implementation

### Getting Article

Location: `lib/src/data/in_memory_news_data_source.dart`

```dart
@override
Future<Article?> getArticle({
  required String id,
  int limit = 20,
  int offset = 0,
  bool preview = false,
}) async {
  // Find the article
  final result = _newsItems.where((item) => item.post.id == id);
  if (result.isEmpty) return null;
  final articleNewsItem = result.first;

  // Get content (full or preview)
  final article = (preview
          ? articleNewsItem.contentPreview
          : articleNewsItem.content)
      .toArticle(title: articleNewsItem.post.title, url: articleNewsItem.url);

  // Paginate
  final totalBlocks = article.totalBlocks;
  final normalizedOffset = math.min(offset, totalBlocks);
  final blocks =
      article.blocks.sublist(normalizedOffset).take(limit).toList();

  return Article(
    title: article.title,
    blocks: blocks,
    totalBlocks: totalBlocks,
    url: article.url,
  );
}
```

### Checking if Article is Premium

```dart
@override
Future<bool?> isPremiumArticle({required String id}) async {
  final result = _newsItems.where((item) => item.post.id == id);
  if (result.isEmpty) return null;
  return result.first.post.isPremium;
}
```

### Getting Related Articles

```dart
@override
Future<RelatedArticles> getRelatedArticles({
  required String id,
  int limit = 20,
  int offset = 0,
}) async {
  final result = _newsItems.where((item) => item.post.id == id);
  if (result.isEmpty) return const RelatedArticles.empty();

  final articles = result.first.relatedArticles;
  final totalBlocks = articles.length;
  final normalizedOffset = math.min(offset, totalBlocks);
  final blocks = articles.sublist(normalizedOffset).take(limit).toList();

  return RelatedArticles(blocks: blocks, totalBlocks: totalBlocks);
}
```

## Testing Articles

### Test Getting Article

```bash
# Get free article
curl http://localhost:8080/api/v1/articles/free-article-id

# Get premium article (anonymous - preview)
curl http://localhost:8080/api/v1/articles/premium-article-id

# Get premium article (authenticated)
curl http://localhost:8080/api/v1/articles/premium-article-id \
  -H "Authorization: Bearer user123"
```

### Test Pagination

```bash
# First page
curl "http://localhost:8080/api/v1/articles/article-id?limit=10&offset=0"

# Second page
curl "http://localhost:8080/api/v1/articles/article-id?limit=10&offset=10"
```

### Test Related Articles

```bash
curl http://localhost:8080/api/v1/articles/article-id/related
```

## Summary

- Articles are composed of flexible content blocks
- Premium articles require valid subscription for full access
- Support pagination for large content
- Include related articles
- Multiple block types for rich content
- Preview mode available
