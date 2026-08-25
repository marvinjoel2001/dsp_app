class ApiConstants {
  // Backend Base URLs
  static const String baseUrl = 'http://10.0.2.2:3000'; // Default Android Emulator host
  static const String wsUrl = 'http://10.0.2.2:3000/tracking';

  // Mapbox Vector Tile URL & Public Token (NO GOOGLE MAPS!)
  static const String mapboxPublicToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: 'pk.your_mapbox_public_token_here');
  static const String mapboxStyleUrl = 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
  static const String mapboxLightStyleUrl = 'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';

  // Endpoints
  static const String login = '/v1/auth/login';
  static const String registerDriver = '/v1/auth/register-driver';
  static const String driverFeed = '/v1/drivers/{id}/feed';
  static const String driverActiveOrder = '/v1/drivers/{id}/active-order';
  static const String driverToggleOnline = '/v1/drivers/{id}/online';
  static const String driverWallet = '/v1/drivers/{id}/wallet';
  static const String acceptOrder = '/v1/dispatch/accept';
  static const String updateOrderStatus = '/v1/orders/{id}/status';
}
