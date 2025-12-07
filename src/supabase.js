import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://wemridduezkgoqjytknp.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndlbXJpZGR1ZXprZ29xanl0a25wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NzI1MTIsImV4cCI6MjA4MDM0ODUxMn0.G_LFJH2l9TTH1DLZwGvv7re3Cq-Wq0eEbcQ7rnA8JEo'

export const supabase = createClient(supabaseUrl, supabaseKey)
