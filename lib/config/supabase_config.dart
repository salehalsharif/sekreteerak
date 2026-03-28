/// Supabase configuration
/// Replace with your actual Supabase project credentials
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  /// Supabase anonymous key
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  /// OpenAI API key (used in Edge Functions, not client)
  static const String openAiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
}
