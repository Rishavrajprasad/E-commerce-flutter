import 'package:supabase_flutter/supabase_flutter.dart';

// Get these values from your Supabase project settings
const String supabaseUrl = 'https://cjnvgaturoftclihxqwc.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqbnZnYXR1cm9mdGNsaWh4cXdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYyMzIyODcsImV4cCI6MjA1MTgwODI4N30.-m-3G7TvwzwOONWt-22joyk6fNX5rNfYq77TuNtGuJ8';

final supabase = Supabase.instance.client;
