import 'package:flutter/material.dart';
import '../core/models/storefront_models.dart';
import 'store_header_widget.dart';
import 'store_footer_widget.dart';
import 'spacer_widget.dart';
import 'hero_banner_widget.dart';
import 'rich_text_widget.dart';
import 'image_widget.dart';
import 'cta_widget.dart';
import 'faq_widget.dart';
import 'feature_grid_widget.dart';
import 'testimonials_widget.dart';
import 'pricing_table_widget.dart';
import 'stats_counter_widget.dart';
import 'logo_cloud_widget.dart';
import 'timeline_widget.dart';
import 'screenshot_showcase_widget.dart';
import 'built_with_widget.dart';
import 'image_gallery_widget.dart';
import 'hero_carousel_widget.dart';
import 'category_grid_widget.dart';
import 'product_shelf_widget.dart';
import 'product_featured_widget.dart';
import 'search_results_widget.dart';
import 'product_listing_widget.dart';
import 'product_detail_widget.dart';
import 'product_reviews_widget.dart';
import 'cart_widget.dart';
import 'checkout_widget.dart';
import 'auth_widget.dart';
import 'mini_cart_widget.dart';
import 'orders_widget.dart';
import 'my_account_widget.dart';
import 'b2b_dashboard_widget.dart';
import 'b2b_quick_order_widget.dart';
import 'b2b_quotes_widget.dart';
import 'b2b_credit_widget.dart';
import 'b2b_reorder_widget.dart';

Widget resolveWidget(
  StorefrontWidget widget, {
  required StorefrontResolveResponse storefront,
  String? slug,
}) {
  final cfg = widget.config;
  final btns = widget.buttons;

  switch (widget.name) {
    case 'store-header':
      return StoreHeaderWidget(config: cfg, storefront: storefront);
    case 'store-footer':
      return StoreFooterWidget(config: cfg, storefront: storefront);
    case 'spacer':
      return SpacerWidget(config: cfg);
    case 'hero-banner':
      return HeroBannerWidget(config: cfg, buttons: btns, storefront: storefront);
    case 'rich-text':
      return RichTextWidget(config: cfg, storefront: storefront);
    case 'image':
      return ImageWidget(config: cfg);
    case 'cta':
      return CtaWidget(config: cfg, buttons: btns, storefront: storefront);
    case 'faq':
      return FaqWidget(config: cfg, storefront: storefront);
    case 'feature-grid':
      return FeatureGridWidget(config: cfg, storefront: storefront);
    case 'testimonials':
      return TestimonialsWidget(config: cfg, storefront: storefront);
    case 'pricing-table':
      return PricingTableWidget(config: cfg, buttons: btns, storefront: storefront);
    case 'stats-counter':
      return StatsCounterWidget(config: cfg, storefront: storefront);
    case 'logo-cloud':
      return LogoCloudWidget(config: cfg, storefront: storefront);
    case 'timeline':
      return TimelineWidget(config: cfg, storefront: storefront);
    case 'screenshot-showcase':
      return ScreenshotShowcaseWidget(config: cfg, storefront: storefront);
    case 'built-with':
      return BuiltWithWidget(config: cfg, storefront: storefront);
    case 'image-gallery':
      return ImageGalleryWidget(config: cfg, storefront: storefront);
    case 'hero-carousel':
      return HeroCarouselWidget(config: cfg, buttons: btns, storefront: storefront);
    case 'category-grid':
      return CategoryGridWidget(config: cfg, storefront: storefront);
    case 'product-shelf':
      return ProductShelfWidget(config: cfg, storefront: storefront);
    case 'product-featured':
      return ProductFeaturedWidget(config: cfg, storefront: storefront);
    case 'search-results':
      return SearchResultsWidget(config: cfg, storefront: storefront);
    case 'product-listing':
      return ProductListingWidget(config: cfg, storefront: storefront, categorySlug: slug);
    case 'product-detail':
    case 'product-details':
      return ProductDetailWidget(config: cfg, storefront: storefront, slug: slug);
    case 'product-reviews':
      return ProductReviewsWidget(config: cfg, storefront: storefront);
    case 'cart-items':
      return CartWidget(config: cfg, storefront: storefront);
    case 'checkout-summary':
      return CheckoutWidget(config: cfg, storefront: storefront);
    case 'auth-section':
      return AuthWidget(config: cfg, storefront: storefront);
    case 'mini-cart':
      return MiniCartWidget(config: cfg, storefront: storefront);
    case 'orders-section':
      return OrdersWidget(config: cfg, storefront: storefront);
    case 'my-account-section':
      return MyAccountWidget(config: cfg, storefront: storefront);
    case 'b2b-dashboard-section':
      return B2bDashboardWidget(config: cfg, storefront: storefront);
    case 'b2b-quick-order-section':
      return B2bQuickOrderWidget(config: cfg, storefront: storefront);
    case 'b2b-quotes-section':
      return B2bQuotesWidget(config: cfg, storefront: storefront);
    case 'b2b-credit-section':
      return B2bCreditWidget(config: cfg, storefront: storefront);
    case 'b2b-reorder-section':
      return B2bReorderWidget(config: cfg, storefront: storefront);
    default:
      return const SizedBox.shrink();
  }
}
