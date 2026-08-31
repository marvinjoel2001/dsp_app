class ApiConstants {
  // App Branding
  static const String appName = 'Chiringuito Driver';

  // Backend Base URLs (Producción Render Cloud por defecto)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dsp-backend-q3mn.onrender.com',
  );
  static const String wsUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'https://dsp-backend-q3mn.onrender.com/tracking',
  );

  // Mapbox Vector Tile URL & Public Token (Cargado vía dart-defines)
  static const String mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  // Mapbox Light Theme Vector Tiles (Modo Light Nítido y de Alta Velocidad)
  static const String mapboxLightStyleUrl =
      'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
  static const String mapboxStreetsStyleUrl =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';

  // Cloudinary Storage Config (Cargado vía dart-defines)
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dpdpgl5kg',
  );
  static const String cloudinaryApiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '494851424798979',
  );
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'chamba',
  );

  // Endpoints
  static const String login = '/v1/auth/login';
  static const String registerDriver = '/v1/auth/register-driver';
  static const String driverProfile = '/v1/drivers/{id}';
  static const String driverUpdateProfile = '/v1/drivers/{id}/profile';
  static const String driverUploadDocuments = '/v1/drivers/{id}/documents';
  static const String driverFeed = '/v1/drivers/{id}/feed';
  static const String driverActiveOrder = '/v1/drivers/{id}/active-order';
  static const String driverToggleOnline = '/v1/drivers/{id}/online';
  static const String driverWallet = '/v1/drivers/{id}/wallet';
  static const String driverUpdateFcmToken = '/v1/drivers/{id}/fcm-token';
  static const String acceptOrder = '/v1/dispatch/accept';
  static const String updateOrderStatus = '/v1/orders/{id}/status';
}
