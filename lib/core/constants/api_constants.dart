// API定数
class ApiConstants {
  ApiConstants._();

  // Supabase設定
  static const String supabaseUrl = 'https://dkahbzefeoyqtmbaozce.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrYWhiemVmZW95cXRtYmFvemNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzOTA1NzUsImV4cCI6MjA4MTk2NjU3NX0.FZ6D-AunpHPRIVivq6DsDyFoVb3hlvbL1UGYOb9-rVM';

  // Edge Function エンドポイント
  static const String fetchNoaaDataEndpoint =
      '$supabaseUrl/functions/v1/fetch-noaa-data';

  // タイムアウト設定
  static const Duration apiTimeout = Duration(seconds: 30);

  // キャッシュ有効期限
  static const Duration cacheExpiry = Duration(minutes: 5);
}
