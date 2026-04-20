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

  const StorefrontLogo({this.hdUrl, this.smUrl, this.altText});

  factory StorefrontLogo.fromJson(Map<String, dynamic> json) {
    return StorefrontLogo(
      hdUrl: json['hdUrl'] as String?,
      smUrl: json['smUrl'] as String?,
      altText: json['altText'] as String?,
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

  const StorefrontResolveResponse({
    this.storeName,
    this.theme,
    this.logo,
    this.publicToken,
    this.b2bEnabled = false,
    this.settings,
  });

  factory StorefrontResolveResponse.fromJson(Map<String, dynamic> json) {
    return StorefrontResolveResponse(
      storeName: json['storeName'] as String?,
      theme: json['theme'] != null
          ? StorefrontTheme.fromJson(json['theme'] as Map<String, dynamic>)
          : null,
      logo: json['logo'] != null
          ? StorefrontLogo.fromJson(json['logo'] as Map<String, dynamic>)
          : null,
      publicToken: json['publicToken'] as String?,
      b2bEnabled: json['b2bEnabled'] as bool? ?? false,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}

class StorefrontWidget {
  final String name;
  final Map<String, dynamic> config;
  final List<WidgetButton> buttons;
  final String? id;

  const StorefrontWidget({
    required this.name,
    required this.config,
    required this.buttons,
    this.id,
  });

  factory StorefrontWidget.fromJson(Map<String, dynamic> json) {
    final rawButtons = json['buttons'] as List<dynamic>? ?? [];
    return StorefrontWidget(
      name: json['name'] as String? ?? '',
      config: json['config'] as Map<String, dynamic>? ?? {},
      buttons: rawButtons
          .map((b) => WidgetButton.fromJson(b as Map<String, dynamic>))
          .toList(),
      id: json['id'] as String?,
    );
  }
}

class WidgetButton {
  final String label;
  final String? url;
  final String? variant;
  final String? color;

  const WidgetButton({
    required this.label,
    this.url,
    this.variant,
    this.color,
  });

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
  final Map<String, dynamic> config;

  const StorefrontRow({required this.columns, required this.config});

  factory StorefrontRow.fromJson(Map<String, dynamic> json) {
    final rawCols = json['columns'] as List<dynamic>? ?? [];
    return StorefrontRow(
      columns: rawCols
          .map((c) => StorefrontColumn.fromJson(c as Map<String, dynamic>))
          .toList(),
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }
}

class StorefrontArea {
  final String name;
  final List<StorefrontRow> rows;

  const StorefrontArea({required this.name, required this.rows});

  factory StorefrontArea.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    return StorefrontArea(
      name: json['name'] as String? ?? '',
      rows: rawRows
          .map((r) => StorefrontRow.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StorefrontLayoutTemplate {
  final String name;
  final List<StorefrontArea> areas;

  const StorefrontLayoutTemplate({required this.name, required this.areas});

  factory StorefrontLayoutTemplate.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'] as List<dynamic>? ?? [];
    return StorefrontLayoutTemplate(
      name: json['name'] as String? ?? '',
      areas: rawAreas
          .map((a) => StorefrontArea.fromJson(a as Map<String, dynamic>))
          .toList(),
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
      title: json['title'] as String?,
      description: json['description'] as String?,
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
    return StorefrontPage(
      title: json['title'] as String?,
      pageType: json['pageType'] as String?,
      path: json['path'] as String?,
      layout: json['layout'] != null
          ? StorefrontLayoutTemplate.fromJson(
              json['layout'] as Map<String, dynamic>)
          : null,
      seo: json['seo'] != null
          ? StorefrontPageSeo.fromJson(json['seo'] as Map<String, dynamic>)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
