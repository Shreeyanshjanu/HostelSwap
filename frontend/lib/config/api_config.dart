import 'package:frontend/config/app_constants.dart';

class ApiConfig {
  static const String baseUrl = AppConstants.fastApiBaseUrl;
  
  // FastAPI Endpoints
  static const String chatEndpoint = '$baseUrl/chat';
  static const String ragQueryEndpoint = '$baseUrl/rag-query';
  static const String showContactEndpoint = '$baseUrl/show-contact';
  static const String finalizeSwapEndpoint = '$baseUrl/finalize-swap';
  static const String withdrawRequestEndpoint = '$baseUrl/withdraw-request';
  static const String healthCheckEndpoint = '$baseUrl/health';
}