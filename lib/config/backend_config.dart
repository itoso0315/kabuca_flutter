const kabucaProductionBackendBaseUrl = 'https://kabuca-api.onrender.com';

const kabucaBackendBaseUrl = String.fromEnvironment(
  'KABUCA_BACKEND_BASE_URL',
  defaultValue: kabucaProductionBackendBaseUrl,
);
