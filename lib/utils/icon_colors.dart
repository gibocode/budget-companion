import 'package:flutter/material.dart';

/// Distinct colors for expense/account icons (flat, no 3D). 16 selections.
const List<Color> iconColors = [
  Color(0xFF2563EB), // blue
  Color(0xFF059669), // emerald
  Color(0xFFD97706), // amber
  Color(0xFF7C3AED), // violet
  Color(0xFF0891B2), // cyan
  Color(0xFFDC2626), // red
  Color(0xFFDB2777), // pink
  Color(0xFF4F46E5), // indigo
  Color(0xFF0D9488), // teal
  Color(0xFF65A30D), // lime
  Color(0xFFCA8A04), // yellow
  Color(0xFFEA580C), // orange
  Color(0xFF9333EA), // purple
  Color(0xFF0369A1), // sky
  Color(0xFFBE185D), // rose
  Color(0xFF78716C), // stone
];

/// Returns a consistent color for an item by index (expense, account, etc.).
Color colorForIndex(int index) {
  return iconColors[index % iconColors.length];
}

/// Returns a light background color for the icon container.
Color iconContainerColorForIndex(int index) {
  final c = colorForIndex(index);
  return c.withValues(alpha: 0.15);
}

/// Material icon code points for category icon picker (~50+ finance-related).
List<int> get categoryIconCodePoints => [
  Icons.account_balance_rounded.codePoint,
  Icons.account_balance_wallet_rounded.codePoint,
  Icons.attach_money_rounded.codePoint,
  Icons.payments_rounded.codePoint,
  Icons.savings_rounded.codePoint,
  Icons.credit_card_rounded.codePoint,
  Icons.credit_score_rounded.codePoint,
  Icons.receipt_long_rounded.codePoint,
  Icons.receipt_rounded.codePoint,
  Icons.request_quote_rounded.codePoint,
  Icons.wallet_rounded.codePoint,
  Icons.monetization_on_rounded.codePoint,
  Icons.price_change_rounded.codePoint,
  Icons.trending_up_rounded.codePoint,
  Icons.trending_down_rounded.codePoint,
  Icons.show_chart_rounded.codePoint,
  Icons.shopping_cart_rounded.codePoint,
  Icons.shopping_basket_rounded.codePoint,
  Icons.store_rounded.codePoint,
  Icons.storefront_rounded.codePoint,
  Icons.restaurant_rounded.codePoint,
  Icons.restaurant_menu_rounded.codePoint,
  Icons.lunch_dining_rounded.codePoint,
  Icons.local_atm_rounded.codePoint,
  Icons.local_offer_rounded.codePoint,
  Icons.card_giftcard_rounded.codePoint,
  Icons.card_membership_rounded.codePoint,
  Icons.payment_rounded.codePoint,
  Icons.money_rounded.codePoint,
  Icons.money_off_rounded.codePoint,
  Icons.point_of_sale_rounded.codePoint,
  Icons.inventory_rounded.codePoint,
  Icons.local_shipping_rounded.codePoint,
  Icons.directions_car_rounded.codePoint,
  Icons.directions_bus_rounded.codePoint,
  Icons.flight_rounded.codePoint,
  Icons.train_rounded.codePoint,
  Icons.two_wheeler_rounded.codePoint,
  Icons.local_gas_station_rounded.codePoint,
  Icons.electric_car_rounded.codePoint,
  Icons.medical_services_rounded.codePoint,
  Icons.local_hospital_rounded.codePoint,
  Icons.local_pharmacy_rounded.codePoint,
  Icons.child_care_rounded.codePoint,
  Icons.school_rounded.codePoint,
  Icons.menu_book_rounded.codePoint,
  Icons.library_books_rounded.codePoint,
  Icons.fitness_center_rounded.codePoint,
  Icons.sports_esports_rounded.codePoint,
  Icons.movie_rounded.codePoint,
  Icons.music_note_rounded.codePoint,
  Icons.pets_rounded.codePoint,
  Icons.yard_rounded.codePoint,
  Icons.home_rounded.codePoint,
  Icons.bolt_rounded.codePoint,
  Icons.wifi_rounded.codePoint,
  Icons.plumbing_rounded.codePoint,
  Icons.electrical_services_rounded.codePoint,
  Icons.build_rounded.codePoint,
  Icons.category_rounded.codePoint,
  Icons.volunteer_activism_rounded.codePoint,
  Icons.more_horiz_rounded.codePoint,
  Icons.work_rounded.codePoint,
  Icons.business_center_rounded.codePoint,
  Icons.insert_chart_rounded.codePoint,
  Icons.pie_chart_rounded.codePoint,
  // Extra finance / general-purpose icons
  Icons.ssid_chart_rounded.codePoint,
  Icons.stacked_bar_chart_rounded.codePoint,
  Icons.savings_outlined.codePoint,
  Icons.price_check_rounded.codePoint,
];

/// IconData from Material Icons by code point.
IconData iconDataFromCodePoint(int codePoint) {
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}

/// Color from int ARGB value.
Color colorFromValue(int value) {
  return Color(value);
}
