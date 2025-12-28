# Ads Guide

This guide provides detailed information about how advertisements work in the Propaganda API.

## Overview

The Propaganda API supports banner advertisements that are integrated into news feeds and article content. Ad display is controlled based on user subscription tier, with premium subscribers receiving an ad-free experience.

## Ad Data Models

### Banner Ad Block Model

Location: `packages/news_blocks/lib/src/banner_ad_block.dart`

```dart
@JsonSerializable()
class BannerAdBlock with EquatableMixin implements NewsBlock {
  const BannerAdBlock({
    required this.size,
    this.type = BannerAdBlock.identifier,
  });

  static const identifier = '__banner_ad__';
  final BannerAdSize size;
  @override
  final String type;
}
```

### Banner Ad Size Enum

```dart
enum BannerAdSize {
  normal,           // Standard banner ad
  large,            // Large banner ad
  extraLarge,       // Extra large banner ad
  anchoredAdaptive  // Anchored adaptive banner
}
```

## Ad Display Strategy

### Ad Placement Rules

Ads are strategically placed throughout the application based on user subscription tier:

| User Type | Ad Frequency | Ad Types |
|-----------|--------------|----------|
| Anonymous | Full | All banner ad sizes |
| Authenticated (None) | Full | All banner ad sizes |
| Basic | Reduced | Medium and small ads |
| Plus | Minimal | Small ads only |
| Premium | None | No ads |

### Ad Placement Locations

1. **News Feeds**
   - Every N blocks (configurable)
   - Between articles
   - At end of feed

2. **Articles**
   - Between content sections
   - After specific paragraph counts
   - Before/after media blocks

3. **Premium Articles**
   - Shown to non-subscribers only
   - Removed for premium subscribers

### Ad Block Examples

#### Normal Banner Ad
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

#### Extra Large Banner Ad
```json
{
  "type": "__banner_ad__",
  "size": "extraLarge"
}
```

#### Anchored Adaptive Banner Ad
```json
{
  "type": "__banner_ad__",
  "size": "anchoredAdaptive"
}
```

## Ad Integration in Content

### Feed with Ads

Example feed response with ads:

```json
{
  "feed": [
    {
      "type": "__section_header__",
      "title": "Breaking News"
    },
    {
      "type": "__post_large__",
      "id": "article-1",
      "category": "technology",
      "author": "John Doe",
      "title": "Tech News",
      "imageUrl": "https://example.com/image.jpg"
    },
    {
      "type": "__banner_ad__",
      "size": "normal"
    },
    {
      "type": "__post_medium__",
      "id": "article-2",
      "category": "sports",
      "author": "Jane Smith",
      "title": "Sports Update"
    },
    {
      "type": "__banner_ad__",
      "size": "large"
    },
    {
      "type": "__divider_horizontal__"
    },
    {
      "type": "__post_small__",
      "id": "article-3",
      "category": "health",
      "author": "Bob Johnson",
      "title": "Health Tips"
    }
  ],
  "total_count": 20
}
```

### Article with Ads

Example article content with ads:

```json
{
  "title": "Article Title",
  "content": [
    {
      "type": "__article_introduction__",
      "category": "technology",
      "title": "Article Title",
      "author": "John Doe",
      "imageUrl": "https://example.com/image.jpg"
    },
    {
      "type": "__text_paragraph__",
      "content": "First paragraph..."
    },
    {
      "type": "__image__",
      "url": "https://example.com/article-image.jpg"
    },
    {
      "type": "__banner_ad__",
      "size": "normal"
    },
    {
      "type": "__text_paragraph__",
      "content": "Second paragraph..."
    },
    {
      "type": "__banner_ad__",
      "size": "large"
    },
    {
      "type": "__text_paragraph__",
      "content": "Third paragraph..."
    }
  ],
  "total_count": 42,
  "url": "https://example.com/article",
  "isPremium": false,
  "isPreview": false
}
```

## Ad Block Serialization

### Deserializing Banner Ad Blocks

The `NewsBlock.fromJson()` method handles deserialization:

```dart
static NewsBlock fromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    // ... other block types
    case BannerAdBlock.identifier:
      return BannerAdBlock.fromJson(json);
    // ... other block types
  }
  return const UnknownBlock();
}
```

### Serializing Banner Ad Blocks

Banner ad blocks are automatically serialized to JSON:

```dart
final adBlock = BannerAdBlock(size: BannerAdSize.normal);
final json = adBlock.toJson();

// Result:
// {
//   "type": "__banner_ad__",
//   "size": "normal"
// }
```

## Ad Display Logic

### Determining Ad Frequency

```dart
int getAdFrequency(User user) {
  switch (user.subscription) {
    case SubscriptionPlan.none:
      return 5;  // Every 5 blocks
    case SubscriptionPlan.basic:
      return 10; // Every 10 blocks
    case SubscriptionPlan.plus:
      return 20; // Every 20 blocks
    case SubscriptionPlan.premium:
      return -1; // No ads
  }
}
```

### Filtering Ads for Premium Users

```dart
List<NewsBlock> filterAdsForUser(
  List<NewsBlock> blocks,
  User user,
) {
  if (user.subscription == SubscriptionPlan.premium) {
    return blocks.where((block) =>
      block.type != BannerAdBlock.identifier
    ).toList();
  }
  return blocks;
}
```

### Inserting Ads in Feed

```dart
List<NewsBlock> insertAdsInFeed(
  List<NewsBlock> blocks,
  User user,
) {
  final adFrequency = getAdFrequency(user);

  if (adFrequency == -1) return blocks;  // No ads for premium

  final result = <NewsBlock>[];
  for (var i = 0; i < blocks.length; i++) {
    result.add(blocks[i]);

    // Insert ad at specified interval
    if (i > 0 && i % adFrequency == 0) {
      final adSize = _selectAdSize(user);
      result.add(BannerAdBlock(size: adSize));
    }
  }

  return result;
}
```

### Selecting Ad Size

```dart
BannerAdSize _selectAdSize(User user) {
  switch (user.subscription) {
    case SubscriptionPlan.none:
    case SubscriptionPlan.basic:
      return BannerAdSize.normal;
    case SubscriptionPlan.plus:
      return BannerAdSize.large;
    case SubscriptionPlan.premium:
      throw StateError('No ads for premium users');
  }
}
```

## Ad Rendering

### Client-Side Ad Rendering

Clients render banner ad blocks differently from content blocks:

```dart
Widget buildBlock(NewsBlock block) {
  if (block is BannerAdBlock) {
    return BannerAdWidget(
      size: block.size,
      onAdLoaded: () => analytics.track('ad_loaded'),
      onAdClicked: () => analytics.track('ad_clicked'),
    );
  }

  // Render other block types
  return ContentBlockWidget(block: block);
}
```

### Ad Widget Example

```dart
class BannerAdWidget extends StatelessWidget {
  final BannerAdSize size;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdClicked;

  const BannerAdWidget({
    super.key,
    required this.size,
    this.onAdLoaded,
    this.onAdClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _getHeight(size),
      color: Colors.grey[200],
      child: AdBanner(
        size: size,
        onLoaded: onAdLoaded,
        onClicked: onAdClicked,
      ),
    );
  }

  double _getHeight(BannerAdSize size) {
    switch (size) {
      case BannerAdSize.normal:
        return 50;
      case BannerAdSize.large:
        return 90;
      case BannerAdSize.extraLarge:
        return 250;
      case BannerAdSize.anchoredAdaptive:
        return 60;
    }
  }
}
```

## Ad Analytics

### Tracking Ad Events

```dart
class AdAnalytics {
  void trackAdViewed(String adId, BannerAdSize size) {
    analytics.track('ad_viewed', {
      'ad_id': adId,
      'size': size.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackAdClicked(String adId) {
    analytics.track('ad_clicked', {
      'ad_id': adId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void trackAdLoaded(String adId, Duration loadTime) {
    analytics.track('ad_loaded', {
      'ad_id': adId,
      'load_time_ms': loadTime.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### Ad Performance Metrics

```dart
class AdMetrics {
  int totalViews;
  int totalClicks;
  double clickThroughRate;
  Map<BannerAdSize, int> viewsBySize;
  Map<BannerAdSize, int> clicksBySize;
  double averageLoadTimeMs;
}
```

## Ad Configuration

### Ad Configuration Model

```dart
class AdConfiguration {
  final int frequency;
  final List<BannerAdSize> allowedSizes;
  final bool enabled;

  const AdConfiguration({
    required this.frequency,
    required this.allowedSizes,
    required this.enabled,
  });
}
```

### Subscription-Based Ad Configuration

```dart
Map<SubscriptionPlan, AdConfiguration> get adConfigurations => {
  SubscriptionPlan.none: AdConfiguration(
    frequency: 5,
    allowedSizes: BannerAdSize.values,
    enabled: true,
  ),
  SubscriptionPlan.basic: AdConfiguration(
    frequency: 10,
    allowedSizes: [
      BannerAdSize.normal,
      BannerAdSize.large,
    ],
    enabled: true,
  ),
  SubscriptionPlan.plus: AdConfiguration(
    frequency: 20,
    allowedSizes: [
      BannerAdSize.normal,
    ],
    enabled: true,
  ),
  SubscriptionPlan.premium: AdConfiguration(
    frequency: -1,
    allowedSizes: [],
    enabled: false,
  ),
};
```

## Ad Use Cases

### Use Case 1: Standard Ad Display

Anonymous user browsing news feed:

```bash
# Get feed with full ad experience
curl http://localhost:8080/api/v1/feed

# Response includes ads every 5 blocks
```

### Use Case 2: Reduced Ad Display

Basic subscriber browsing feed:

```bash
# Get feed with reduced ads
curl http://localhost:8080/api/v1/feed \
  -H "Authorization: Bearer basic-user"

# Response includes ads every 10 blocks
```

### Use Case 3: Minimal Ad Display

Plus subscriber browsing feed:

```bash
# Get feed with minimal ads
curl http://localhost:8080/api/v1/feed \
  -H "Authorization: Bearer plus-user"

# Response includes ads every 20 blocks
```

### Use Case 4: No Ad Display

Premium subscriber browsing feed:

```bash
# Get feed without ads
curl http://localhost:8080/api/v1/feed \
  -H "Authorization: Bearer premium-user"

# Response contains no banner ad blocks
```

### Use Case 5: Ad in Article

User reading free article:

```bash
# Get article with ads
curl http://localhost:8080/api/v1/articles/free-article-id

# Response includes ads between content blocks
```

### Use Case 6: No Ad in Premium Article

Premium subscriber reading premium article:

```bash
# Get premium article without ads
curl http://localhost:8080/api/v1/articles/premium-article-id \
  -H "Authorization: Bearer premium-user"

# Response contains no banner ad blocks
```

## Ad Management

### Adding New Ad Size

1. Add new size to `BannerAdSize` enum:

```dart
enum BannerAdSize {
  normal,
  large,
  extraLarge,
  anchoredAdaptive,
  leaderboard,  // New size
}
```

2. Update client-side rendering to handle new size:

```dart
double _getHeight(BannerAdSize size) {
  switch (size) {
    case BannerAdSize.leaderboard:
      return 90;
    // ... existing sizes
  }
}
```

### Configuring Ad Frequency

Update ad configuration based on business requirements:

```dart
Map<SubscriptionPlan, AdConfiguration> adConfigurations => {
  SubscriptionPlan.none: AdConfiguration(
    frequency: 3,  // Changed from 5
    allowedSizes: BannerAdSize.values,
    enabled: true,
  ),
  // ... other configurations
};
```

### Disabling Ads Temporarily

```dart
AdConfiguration getAdConfiguration(User user) {
  final config = adConfigurations[user.subscription];

  // Global ad disable
  if (!_adsEnabled) {
    return AdConfiguration(
      frequency: -1,
      allowedSizes: [],
      enabled: false,
    );
  }

  return config;
}
```

## Testing Ads

### Test Ad Display in Feed

```bash
# Anonymous user - full ads
curl http://localhost:8080/api/v1/feed | jq '.feed[] | select(.type == "__banner_ad__")'

# Premium user - no ads
curl http://localhost:8080/api/v1/feed \
  -H "Authorization: Bearer premium-user" | jq '.feed[] | select(.type == "__banner_ad__")'
```

### Test Ad Display in Article

```bash
# Get article with ads
curl http://localhost:8080/api/v1/articles/article-id | jq '.content[] | select(.type == "__banner_ad__")'
```

### Test Ad Frequency

```bash
# Count ads in feed
curl -s http://localhost:8080/api/v1/feed | jq '[.feed[] | select(.type == "__banner_ad__")] | length'
```

## Ad Provider Integration

### Ad Provider Interface

```dart
abstract class AdProvider {
  Future<Ad> loadAd(BannerAdSize size);
  void trackImpression(String adId);
  void trackClick(String adId);
}
```

### Google AdMob Integration Example

```dart
class AdMobProvider implements AdProvider {
  @override
  Future<Ad> loadAd(BannerAdSize size) async {
    final adUnitId = _getAdUnitId(size);
    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: _getAdSize(size),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (_, error) {},
      ),
    );

    await bannerAd.load();
    return AdMobAd(bannerAd);
  }

  String _getAdUnitId(BannerAdSize size) {
    switch (size) {
      case BannerAdSize.normal:
        return 'ca-app-pub-1234567890/1234567890';
      // ... other sizes
    }
  }

  AdSize _getAdSize(BannerAdSize size) {
    switch (size) {
      case BannerAdSize.normal:
        return AdSize.banner;
      case BannerAdSize.large:
        return AdSize.largeBanner;
      case BannerAdSize.extraLarge:
        return AdSize.IABBanner;
      case BannerAdSize.anchoredAdaptive:
        return AdSize.fluid;
    }
  }
}
```

## Ad Performance Optimization

### Lazy Loading Ads

```dart
class LazyAdWidget extends StatefulWidget {
  final BannerAdSize size;

  const LazyAdWidget({super.key, required this.size});

  @override
  State<LazyAdWidget> createState() => _LazyAdWidgetState();
}

class _LazyAdWidgetState extends State<LazyAdWidget> {
  bool _loadAd = false;

  @override
  void initState() {
    super.initState();
    // Load ad when widget comes into view
    _checkVisibility();
  }

  void _checkVisibility() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() => _loadAd = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('ad-${widget.size}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          setState(() => _loadAd = true);
        }
      },
      child: _loadAd
          ? BannerAdWidget(size: widget.size)
          : const SizedBox.shrink(),
    );
  }
}
```

### Ad Caching

```dart
class AdCache {
  final Map<BannerAdSize, Ad?> _cache = {};

  Future<Ad> getAd(BannerAdSize size) async {
    if (_cache.containsKey(size) && _cache[size] != null) {
      return _cache[size]!;
    }

    final ad = await adProvider.loadAd(size);
    _cache[size] = ad;
    return ad;
  }

  void clear() {
    _cache.clear();
  }
}
```

## Summary

- Banner ads integrated into feeds and articles
- Ad display controlled by subscription tier
- Multiple ad sizes supported
- Premium subscribers receive ad-free experience
- Client-side rendering with analytics tracking
- Configurable ad frequency and placement
