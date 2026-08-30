// lib/config/app_constants.dart

class AppConstants {
  // Supabase Configuration (same as before)
  static const String supabaseUrl = 'https://ycknhuoexocrjtvllyqx.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Sf5U9Di77ObbXoMZLABLzA_-YNfo6Ey';
  
  // Hostel Lists (update with your actual hostels)
  static const List<String> boysHostels = ['BH-1', 'BH-2', 'BH-3'];
  static const List<String> girlsHostels = ['GH-1', 'GH-2', 'GH-3'];
  static const List<String> allHostels = [...boysHostels, ...girlsHostels];
  
  static const List<int> seaterTypes = [2, 3, 4, 5];
  static const List<String> acTypes = ['AC', 'Non-AC'];
  static const List<String> genders = ['male', 'female', 'other'];
  
  static const int maxActiveRequests = 5;
  static const int requestExpiryDays = 5;
}