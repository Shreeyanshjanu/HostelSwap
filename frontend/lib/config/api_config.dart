// lib/config/api_config.dart

class ApiConfig {
  // 🔥 YOUR NGROK URL
  static const String baseUrl =
      'https://slapstick-riverboat-bulb.ngrok-free.dev';

  // 🔥 MAKE SURE THESE ENDPOINTS MATCH YOUR BACKEND
  static const String healthEndpoint = '$baseUrl/health';
  static const String healthCheckEndpoint = '$baseUrl/health';
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String updateTokenEndpoint = '$baseUrl/auth/update-token';
  static const String getRequestsEndpoint = '$baseUrl/requests';
  static const String getUserRequestsEndpoint = '$baseUrl/requests/my';
  static const String createRequestEndpoint = '$baseUrl/requests/create';
  static const String withdrawRequestEndpoint = '$baseUrl/requests/withdraw';
  static const String expressInterestEndpoint = '$baseUrl/interests/express';
  static const String getApplicantsEndpoint = '$baseUrl/interests/applicants';

  // 🔥 CHAT ENDPOINT - Make sure this is correct
  static const String chatEndpoint = '$baseUrl/chat';

  static const String showContactEndpoint = '$baseUrl/show-contact';
  static const String finalizeSwapEndpoint = '$baseUrl/finalize-swap';
  static const String ragQueryEndpoint = '$baseUrl/rag/query';
  static const String ragHealthEndpoint = '$baseUrl/rag/health';
  static const String ragIngestEndpoint = '$baseUrl/rag/ingest';
}
