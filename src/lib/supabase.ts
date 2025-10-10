import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Type definitions for your database
export type User = {
  id: string
  email: string
  username: string
  full_name?: string
  avatar_url?: string
  role: 'admin' | 'user' | 'guest'
  is_active: boolean
  created_at: string
}

export type Recipe = {
  id: string
  user_id: string
  title: string
  description?: string
  instructions: string[]
  prep_time_minutes?: number
  cook_time_minutes?: number
  servings: number
  is_public: boolean
  image_url?: string
  created_at: string
}