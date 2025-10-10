'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { getCurrentUser } from '@/lib/auth'
import Link from 'next/link'

type Recipe = {
  id: string
  title: string
  description: string
  prep_time_minutes: number
  cook_time_minutes: number
  servings: number
  image_url: string
  is_public: boolean
  user_id: string
  created_at: string
  users: {
    username: string
  }
}

export default function RecipesPage() {
  const [recipes, setRecipes] = useState<Recipe[]>([])
  const [loading, setLoading] = useState(true)
  const [currentUser, setCurrentUser] = useState<any>(null)
  const [filter, setFilter] = useState<'all' | 'my-recipes'>('all')

  useEffect(() => {
    loadRecipes()
    loadCurrentUser()
  }, [filter])

  async function loadCurrentUser() {
    const user = await getCurrentUser()
    setCurrentUser(user)
  }

  async function loadRecipes() {
    setLoading(true)
    
    let query = supabase
      .from('recipes')
      .select(`
        *,
        users!recipes_user_id_fkey (username)
      `)    
      .eq('is_deleted', false)
      .order('created_at', { ascending: false })
  
    // Filter logic
    if (filter === 'all') {
      query = query.eq('is_public', true)
    } else if (filter === 'my-recipes' && currentUser) {
      query = query.eq('user_id', currentUser.id)
    }
  
    const { data, error } = await query
  
    if (error) {
      console.error('Error loading recipes:', error)
    } else {
      setRecipes(data || [])
    }
    
    setLoading(false)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex justify-between items-center">
            <div>
              <Link href="/dashboard" className="text-blue-600 hover:text-blue-800 text-sm">
                ← Back to Dashboard
              </Link>
              <h1 className="text-2xl font-bold text-gray-900 mt-2">Browse Recipes</h1>
            </div>
            <Link
              href="/recipes/new"
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Create Recipe
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filter Tabs */}
        {currentUser && (
          <div className="mb-6 flex gap-2">
            <button
              onClick={() => setFilter('all')}
              className={`px-4 py-2 rounded-md ${
                filter === 'all'
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              All Public Recipes
            </button>
            <button
              onClick={() => setFilter('my-recipes')}
              className={`px-4 py-2 rounded-md ${
                filter === 'my-recipes'
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              My Recipes
            </button>
          </div>
        )}

        {/* Loading State */}
        {loading && (
          <div className="text-center py-12">
            <div className="text-lg text-gray-600">Loading recipes...</div>
          </div>
        )}

        {/* Empty State */}
        {!loading && recipes.length === 0 && (
          <div className="text-center py-12 bg-white rounded-lg shadow">
            <div className="text-6xl mb-4">🍳</div>
            <h3 className="text-xl font-semibold text-gray-900 mb-2">
              {filter === 'my-recipes' ? 'No recipes yet' : 'No public recipes found'}
            </h3>
            <p className="text-gray-600 mb-4">
              {filter === 'my-recipes' 
                ? 'Start by creating your first recipe!'
                : 'Be the first to share a recipe with the community!'}
            </p>
            <Link
              href="/recipes/new"
              className="inline-block px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Create Recipe
            </Link>
          </div>
        )}

        {/* Recipes Grid */}
        {!loading && recipes.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {recipes.map((recipe) => (
              <Link
                key={recipe.id}
                href={`/recipes/${recipe.id}`}
                className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow overflow-hidden"
              >
                {/* Recipe Image */}
                <div className="h-48 bg-gray-200 relative">
                  {recipe.image_url ? (
                    <img
                      src={recipe.image_url}
                      alt={recipe.title}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-6xl">
                      🍽️
                    </div>
                  )}
                  {!recipe.is_public && (
                    <span className="absolute top-2 right-2 px-2 py-1 bg-gray-800 text-white text-xs rounded">
                      Private
                    </span>
                  )}
                </div>

                {/* Recipe Info */}
                <div className="p-4">
                  <h3 className="font-semibold text-lg text-gray-900 mb-2 line-clamp-1">
                    {recipe.title}
                  </h3>
                  <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                    {recipe.description || 'No description provided'}
                  </p>

                  {/* Meta Info */}
                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <div className="flex items-center gap-3">
                      {recipe.prep_time_minutes && (
                        <span>⏱️ {recipe.prep_time_minutes}m</span>
                      )}
                      {recipe.servings && (
                        <span>👥 {recipe.servings}</span>
                      )}
                    </div>
                    <span className="text-xs">by @{recipe.users?.username}</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}