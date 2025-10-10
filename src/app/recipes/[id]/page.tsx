'use client'

import { useEffect, useState } from 'react'
import { useRouter, useParams } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import { getCurrentUser } from '@/lib/auth'
import Link from 'next/link'

type Recipe = {
  id: string
  title: string
  description: string
  instructions: string[]
  prep_time_minutes: number
  cook_time_minutes: number
  total_time_minutes: number
  servings: number
  difficulty_level: string
  cuisine_type: string
  meal_type: string
  image_url: string
  is_public: boolean
  user_id: string
  created_at: string
  users: {
    username: string
  }
}

type RecipeNutrition = {
  calories_per_serving: number
  protein_per_serving: number
  fat_per_serving: number
  carbs_per_serving: number
  fiber_per_serving: number
}

export default function RecipeDetailPage() {
  const params = useParams()
  const router = useRouter()
  const [recipe, setRecipe] = useState<Recipe | null>(null)
  const [nutrition, setNutrition] = useState<RecipeNutrition | null>(null)
  const [currentUser, setCurrentUser] = useState<{id: string} | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    loadRecipe()
    loadCurrentUser()
  }, [params.id])

  async function loadCurrentUser() {
    const user = await getCurrentUser()
    setCurrentUser(user)
  }

  async function loadRecipe() {
    setLoading(true)
    setError('')

    // Fetch recipe
    const { data: recipeData, error: recipeError } = await supabase
      .from('recipes')
      .select(`
        *,
        users!recipes_user_id_fkey (username)
      `)
      .eq('id', params.id)
      .eq('is_deleted', false)
      .single()

    if (recipeError) {
      setError('Recipe not found')
      setLoading(false)
      return
    }

    // Check if user has access to this recipe
    const user = await getCurrentUser()
    if (!recipeData.is_public && recipeData.user_id !== user?.id) {
      setError('You do not have access to this recipe')
      setLoading(false)
      return
    }

    setRecipe(recipeData)

    // Fetch nutrition data
    const { data: nutritionData } = await supabase
      .from('recipe_nutrition')
      .select('*')
      .eq('recipe_id', params.id)
      .single()

    setNutrition(nutritionData)
    setLoading(false)
  }

  async function handleDelete() {
    if (!confirm('Are you sure you want to delete this recipe?')) return

    const { error } = await supabase
      .from('recipes')
      .update({ is_deleted: true, deleted_at: new Date().toISOString() })
      .eq('id', params.id)

    if (error) {
      alert('Failed to delete recipe')
    } else {
      router.push('/recipes')
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-lg">Loading recipe...</div>
      </div>
    )
  }

  if (error || !recipe) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">{error || 'Recipe not found'}</h2>
          <Link href="/recipes" className="text-blue-600 hover:text-blue-800">
            &larr; Back to recipes
          </Link>
        </div>
      </div>
    )
  }

  const isOwner = currentUser?.id === recipe.user_id

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <Link href="/recipes" className="text-blue-600 hover:text-blue-800 text-sm">
            &larr; Back to recipes
          </Link>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Recipe Header */}
        <div className="bg-white rounded-lg shadow-lg overflow-hidden mb-6">
          {/* Recipe Image */}
          <div className="h-64 bg-gray-200 relative">
            {recipe.image_url ? (
              <img
                src={recipe.image_url}
                alt={recipe.title}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-8xl">
                🍽️
              </div>
            )}
            {!recipe.is_public && (
              <span className="absolute top-4 right-4 px-3 py-1 bg-gray-800 text-white text-sm rounded">
                Private Recipe
              </span>
            )}
          </div>

          {/* Recipe Info */}
          <div className="p-6">
            <div className="flex justify-between items-start mb-4">
              <div className="flex-1">
                <h1 className="text-3xl font-bold text-gray-900 mb-2">{recipe.title}</h1>
                <p className="text-gray-600 text-sm">
                  By @{recipe.users?.username} • {new Date(recipe.created_at).toLocaleDateString()}
                </p>
              </div>
              
              {/* Action Buttons (if owner) */}
              {isOwner && (
                <div className="flex gap-2">
                  <Link
                    href={`/recipes/${recipe.id}/edit`}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 text-sm"
                  >
                    Edit
                  </Link>
                  <button
                    onClick={handleDelete}
                    className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 text-sm"
                  >
                    Delete
                  </button>
                </div>
              )}
            </div>

            {recipe.description && (
              <p className="text-gray-700 mb-4">{recipe.description}</p>
            )}

            {/* Recipe Meta */}
            <div className="flex flex-wrap gap-4 py-4 border-t border-b border-gray-200">
              {recipe.prep_time_minutes && (
                <div className="flex items-center gap-2">
                  <span className="text-2xl">⏱️</span>
                  <div>
                    <p className="text-xs text-gray-500">Prep Time</p>
                    <p className="font-semibold">{recipe.prep_time_minutes} min</p>
                  </div>
                </div>
              )}
              {recipe.cook_time_minutes && (
                <div className="flex items-center gap-2">
                  <span className="text-2xl">🔥</span>
                  <div>
                    <p className="text-xs text-gray-500">Cook Time</p>
                    <p className="font-semibold">{recipe.cook_time_minutes} min</p>
                  </div>
                </div>
              )}
              {recipe.servings && (
                <div className="flex items-center gap-2">
                  <span className="text-2xl">👥</span>
                  <div>
                    <p className="text-xs text-gray-500">Servings</p>
                    <p className="font-semibold">{recipe.servings}</p>
                  </div>
                </div>
              )}
              {recipe.difficulty_level && (
                <div className="flex items-center gap-2">
                  <span className="text-2xl">📊</span>
                  <div>
                    <p className="text-xs text-gray-500">Difficulty</p>
                    <p className="font-semibold capitalize">{recipe.difficulty_level}</p>
                  </div>
                </div>
              )}
            </div>

            {/* Cuisine & Meal Type */}
            <div className="flex gap-2 mt-4">
              {recipe.cuisine_type && (
                <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
                  {recipe.cuisine_type}
                </span>
              )}
              {recipe.meal_type && (
                <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm capitalize">
                  {recipe.meal_type}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Two Column Layout */}
        <div className="grid md:grid-cols-3 gap-6">
          {/* Left Column - Instructions */}
          <div className="md:col-span-2 space-y-6">
            {/* Instructions */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Instructions</h2>
              <ol className="space-y-4">
                {recipe.instructions.map((step, index) => (
                  <li key={index} className="flex gap-4">
                    <span className="flex-shrink-0 w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center font-semibold">
                      {index + 1}
                    </span>
                    <p className="text-gray-700 pt-1">{step}</p>
                  </li>
                ))}
              </ol>
            </div>
          </div>

          {/* Right Column - Nutrition */}
          <div className="space-y-6">
            {nutrition && (
              <div className="bg-white rounded-lg shadow p-6">
                <h2 className="text-xl font-bold text-gray-900 mb-4">Nutrition Facts</h2>
                <p className="text-sm text-gray-500 mb-4">Per serving</p>
                <div className="space-y-3">
                  <div className="flex justify-between pb-2 border-b">
                    <span className="font-semibold">Calories</span>
                    <span>{Math.round(nutrition.calories_per_serving)}</span>
                  </div>
                  <div className="flex justify-between pb-2 border-b">
                    <span className="text-gray-600">Protein</span>
                    <span>{Math.round(nutrition.protein_per_serving)}g</span>
                  </div>
                  <div className="flex justify-between pb-2 border-b">
                    <span className="text-gray-600">Carbs</span>
                    <span>{Math.round(nutrition.carbs_per_serving)}g</span>
                  </div>
                  <div className="flex justify-between pb-2 border-b">
                    <span className="text-gray-600">Fat</span>
                    <span>{Math.round(nutrition.fat_per_serving)}g</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Fiber</span>
                    <span>{Math.round(nutrition.fiber_per_serving)}g</span>
                  </div>
                </div>
              </div>
            )}

            {/* Quick Actions */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="font-semibold text-gray-900 mb-3">Quick Actions</h3>
              <div className="space-y-2">
                <button className="w-full px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-md text-gray-700 text-sm">
                  ⭐ Add to Favorites
                </button>
                <button className="w-full px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-md text-gray-700 text-sm">
                  📋 Add to Collection
                </button>
                <button className="w-full px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-md text-gray-700 text-sm">
                  📤 Share Recipe
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}