class StorefrontTheme {
  final String? backgroundColor;
  final String? accentColor;
  final String? accentContrastColor;
  final String? textColor;
  final String? mutedTextColor;
  final String? surfaceColor;
  final String? cardBackgroundColor;
  final String? borderColor;
  final String? fontFamilyBody;
  final String? fontFamilyHeading;
  final String? successColor;
  final String? warningColor;
  final String? errorColor;
  final String? infoColor;

  const StorefrontTheme({
    this.backgroundColor,
    this.accentColor,
    this.accentContrastColor,
    this.textColor,
    this.mutedTextColor,
    this.surfaceColor,
    this.cardBackgroundColor,
    this.borderColor,
    this.fontFamilyBody,
    this.fontFamilyHeading,
    this.successColor,
    this.warningColor,
    this.errorColor,
    this.infoColor,
  });

  factory StorefrontTheme.fromJson(Map<String, dynamic> json) {
    return StorefrontTheme(
      backgroundColor: json['backgroundColor'] as String?,
      accentColor: json['accentColor'] as String?,
      accentContrastColor: json['accentContrastColor'] as String?,
      textColor: json['textColor'] as String?,
      mutedTextColor: json['mutedTextColor'] as String?,
      surfaceColor: json['surfaceColor'] as String?,
      cardBackgroundColor: json['cardBackgroundColor'] as String?,
      borderColor: json['borderColor'] as String?,
      fontFamilyBody: json['fontFamilyBody'] as String?,
      fontFamilyHeading: json['fontFamilyHeading'] as String?,
      successColor: json['successColor'] as String?,
      warningColor: json['warningColor'] as String?,
      errorColor: json['errorColor'] as String?,
      infoColor: json['infoColor'] as String?,
    );
  }
}

class StorefrontLogo {
  final String? hdUrl;
  final String? smUrl;
  final String? altText;
  final String? originalUrl;

  const StorefrontLogo({this.hdUrl, this.smUrl, this.altText, this.originalUrl});

  factory StorefrontLogo.fromJson(Map<String, dynamic> json) {
    return StorefrontLogo(
      hdUrl: json['hdUrl'] as String?,
      smUrl: json['smUrl'] as String?,
      altText: json['altText'] as String?,
      originalUrl: json['originalUrl'] as String?,
    );
  }
}

class StorefrontWidget {
  final String name;
  final Map<String, dynamic> config;
  final String? id;
  final StorefrontWidget? mobileOverride;

  const StorefrontWidget({required this.name, required this.config, this.id, this.mobileOverride});

  factory StorefrontWidget.fromJson(Map<String, dynamic> json) {
    final raw = json['configuration'] ?? json['config'];
    Map<String, dynamic> cfg = {};
    if (raw is Map<String, dynamic>) {
      // Flatten content section into cfg, then re-attach layout/style as sub-maps
      // so widgets read flat keys (config['title']) while also having config['layout'] and config['style']
      final content = raw['content'];
      if (content is Map<String, dynamic>) {
        cfg = Map<String, dynamic>.from(content);
        if (raw['layout'] != null) cfg['layout'] = raw['layout'];
        if (raw['style']  != null) cfg['style']  = raw['style'];
      } else {
        cfg = raw;
      }
    }
    StorefrontWidget? mobileOverride;
    final overrideRaw = json['mobileOverride'];
    if (overrideRaw is Map<String, dynamic>) {
      mobileOverride = StorefrontWidget.fromJson(overrideRaw);
    }
    return StorefrontWidget(
      name: json['name'] as String? ?? '',
      config: cfg,
      id: json['id'] as String?,
      mobileOverride: mobileOverride,
    );
  }
}

// WidgetButton kept for compatibility with widget_resolver usage
class WidgetButton {
  final String label;
  final String? url;
  final String? variant;
  final String? color;

  const WidgetButton({required this.label, this.url, this.variant, this.color});

  factory WidgetButton.fromJson(Map<String, dynamic> json) {
    return WidgetButton(
      label: json['label'] as String? ?? '',
      url: json['url'] as String?,
      variant: json['variant'] as String?,
      color: json['color'] as String?,
    );
  }
}

class StorefrontColumn {
  final int span;
  final List<StorefrontWidget> widgets;

  const StorefrontColumn({required this.span, required this.widgets});

  factory StorefrontColumn.fromJson(Map<String, dynamic> json) {
    final rawWidgets = json['widgets'] as List<dynamic>? ?? [];
    return StorefrontColumn(
      span: json['span'] as int? ?? 12,
      widgets: rawWidgets
          .map((w) => StorefrontWidget.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StorefrontRow {
  final List<StorefrontColumn> columns;

  const StorefrontRow({required this.columns});

  factory StorefrontRow.fromJson(Map<String, dynamic> json) {
    final rawCols = json['columns'] as List<dynamic>? ?? [];
    return StorefrontRow(
      columns: rawCols
          .map((c) => StorefrontColumn.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Area supports both flat widgets (layoutTemplate) and rows/columns (page grid)
class StorefrontArea {
  final String name;
  final int position;
  final List<StorefrontWidget> widgets;
  final List<StorefrontRow> rows;

  const StorefrontArea({
    required this.name,
    required this.position,
    required this.widgets,
    required this.rows,
  });

  List<StorefrontWidget> get allWidgets {
    if (rows.isNotEmpty) {
      return rows.expand((r) => r.columns.expand((c) => c.widgets)).toList();
    }
    return widgets;
  }

  factory StorefrontArea.fromJson(Map<String, dynamic> json) {
    final rawWidgets = json['widgets'] as List<dynamic>? ?? [];
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    return StorefrontArea(
      name: json['name'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      widgets: rawWidgets
          .map((w) => StorefrontWidget.fromJson(w as Map<String, dynamic>))
          .toList(),
      rows: rawRows
          .map((r) => StorefrontRow.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StorefrontLayoutTemplate {
  final List<StorefrontArea> areas;

  const StorefrontLayoutTemplate({required this.areas});

  factory StorefrontLayoutTemplate.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'] as List<dynamic>? ?? [];
    return StorefrontLayoutTemplate(
      areas: rawAreas
          .map((a) => StorefrontArea.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StorefrontResolveResponse {
  final String? storeName;
  final StorefrontTheme? theme;
  final StorefrontLogo? logo;
  final String? publicToken;
  final bool b2bEnabled;
  final Map<String, dynamic>? settings;
  final StorefrontLayoutTemplate? layoutTemplate; // header/footer shared areas

  const StorefrontResolveResponse({
    this.storeName,
    this.theme,
    this.logo,
    this.publicToken,
    this.b2bEnabled = false,
    this.settings,
    this.layoutTemplate,
  });

  factory StorefrontResolveResponse.fromJson(Map<String, dynamic> json) {
    // resolve uses "storefrontTheme", not "theme"
    final themeJson = json['storefrontTheme'] ?? json['theme'];
    final layoutJson = json['layoutTemplate'];

    return StorefrontResolveResponse(
      storeName: json['storeName'] as String?,
      theme: themeJson is Map<String, dynamic>
          ? StorefrontTheme.fromJson(themeJson)
          : null,
      logo: json['logo'] is Map<String, dynamic>
          ? StorefrontLogo.fromJson(json['logo'] as Map<String, dynamic>)
          : null,
      publicToken: json['publicToken'] as String?,
      b2bEnabled: json['b2bEnabled'] as bool? ?? false,
      settings: json['settings'] as Map<String, dynamic>?,
      layoutTemplate: layoutJson is Map<String, dynamic>
          ? StorefrontLayoutTemplate.fromJson(layoutJson)
          : null,
    );
  }
}

class StorefrontPageSeo {
  final String? title;
  final String? description;
  final String? ogImage;

  const StorefrontPageSeo({this.title, this.description, this.ogImage});

  factory StorefrontPageSeo.fromJson(Map<String, dynamic> json) {
    return StorefrontPageSeo(
      title: json['title'] as String? ?? json['metaTitle'] as String?,
      description: json['description'] as String? ?? json['metaDescription'] as String?,
      ogImage: json['ogImage'] as String?,
    );
  }
}

class StorefrontPage {
  final String? title;
  final String? pageType;
  final String? path;
  final StorefrontLayoutTemplate? layout;
  final StorefrontPageSeo? seo;
  final Map<String, dynamic>? data;

  const StorefrontPage({
    this.title,
    this.pageType,
    this.path,
    this.layout,
    this.seo,
    this.data,
  });

  factory StorefrontPage.fromJson(Map<String, dynamic> json) {
    final layoutJson = json['publishedLayout'] ?? json['layout'];
    final seoJson = json['publishedSeo'] ?? json['seo'];
    return StorefrontPage(
      title: json['title'] as String?,
      pageType: json['pageType'] as String?,
      path: json['path'] as String?,
      layout: layoutJson is Map<String, dynamic>
          ? StorefrontLayoutTemplate.fromJson(layoutJson)
          : null,
      seo: seoJson is Map<String, dynamic>
          ? StorefrontPageSeo.fromJson(seoJson)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
