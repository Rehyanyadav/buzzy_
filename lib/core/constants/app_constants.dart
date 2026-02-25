class AppConstants {
  // Use --dart-define=supabase_url=... and --dart-define=supabase_anon_key=...
  // for production builds.
  static const String supabaseUrl = String.fromEnvironment(
    'supabase_url',
    defaultValue: 'https://bmlksdpbplczfdclicip.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'supabase_anon_key',
    defaultValue: 'sb_publishable_qe9Jd9XcTj1zoF9qJYiHow_KVTjf7k3',
  );
}
