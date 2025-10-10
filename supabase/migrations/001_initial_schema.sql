-- ============================================
-- USER MANAGEMENT
-- ============================================

-- User roles and profiles
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    password_hash TEXT NOT NULL, -- Encrypted password (bcrypt)
    role TEXT NOT NULL CHECK (role IN ('admin', 'user', 'guest')) DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE, -- Account lockout for security
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences and settings
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    theme TEXT CHECK (theme IN ('light', 'dark', 'system')) DEFAULT 'system',
    default_recipe_visibility TEXT CHECK (default_recipe_visibility IN ('public', 'private')) DEFAULT 'private',
    email_notifications BOOLEAN DEFAULT TRUE,
    dietary_restrictions TEXT[], -- Array of dietary preferences
    favorite_cuisines TEXT[],
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- RECIPE MANAGEMENT
-- ============================================

-- Core recipe information with ownership and visibility
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Recipe owner
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT[], -- Array of step-by-step instructions
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER,
    servings INTEGER DEFAULT 1,
    difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    cuisine_type TEXT,
    meal_type TEXT,
    image_url TEXT,
    
    -- Visibility and access control
    is_public BOOLEAN DEFAULT FALSE, -- Public vs private recipe
    
    -- Source tracking for hybrid approach
    source_url TEXT, -- Original recipe URL if imported
    source_type TEXT CHECK (source_type IN ('api', 'scraped', 'manual', 'ai_generated')),
    spoonacular_id INTEGER,
    api_data JSONB, -- Store raw API response
    
    -- User interaction
    view_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    
    -- Personal tracking
    notes TEXT, -- Private notes for recipe owner only
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    times_cooked INTEGER DEFAULT 0,
    last_cooked_date TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Soft delete (for admin moderation)
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Master ingredient database
CREATE TABLE ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    category TEXT,
    common_unit TEXT,
    usda_food_id TEXT,
    calories_per_100g DECIMAL,
    protein_per_100g DECIMAL,
    fat_per_100g DECIMAL,
    carbs_per_100g DECIMAL,
    fiber_per_100g DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Junction table linking recipes to ingredients
CREATE TABLE recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id),
    quantity DECIMAL,
    unit TEXT,
    preparation TEXT,
    is_optional BOOLEAN DEFAULT FALSE,
    substitute_notes TEXT,
    display_order INTEGER, -- Order to display ingredients
    UNIQUE(recipe_id, ingredient_id)
);

-- Pre-calculated nutrition facts
CREATE TABLE recipe_nutrition (
    recipe_id UUID PRIMARY KEY REFERENCES recipes(id) ON DELETE CASCADE,
    calories_per_serving DECIMAL,
    protein_per_serving DECIMAL,
    fat_per_serving DECIMAL,
    saturated_fat_per_serving DECIMAL,
    carbs_per_serving DECIMAL,
    fiber_per_serving DECIMAL,
    sugar_per_serving DECIMAL,
    sodium_per_serving DECIMAL,
    cholesterol_per_serving DECIMAL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- USER INTERACTIONS
-- ============================================

-- User favorites (many-to-many)
CREATE TABLE user_favorites (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    favorited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, recipe_id)
);

-- Recipe collections/folders
CREATE TABLE collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    cover_image_url TEXT,
    recipe_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE collection_recipes (
    collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    added_by UUID REFERENCES users(id),
    notes TEXT, -- Personal notes about why saved to this collection
    PRIMARY KEY (collection_id, recipe_id)
);

-- User recipe reviews/ratings
CREATE TABLE recipe_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    would_make_again BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id) -- One review per user per recipe
);

-- ============================================
-- AI CHATBOT INTERACTIONS
-- ============================================

-- Chat conversations (null user_id for guest users)
CREATE TABLE chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL for guest users
    session_id TEXT, -- For tracking guest sessions temporarily
    title TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Auto-delete guest conversations after 24 hours
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Individual messages in conversations
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    recipe_context_id UUID REFERENCES recipes(id), -- If message references a specific recipe
    tokens_used INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TAGS & CATEGORIZATION
-- ============================================

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    category TEXT,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE recipe_tags (
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (recipe_id, tag_id)
);

-- ============================================
-- IMPORT & MODERATION
-- ============================================

-- Track all recipe imports
CREATE TABLE import_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
    source_type TEXT NOT NULL,
    source_id TEXT,
    import_status TEXT CHECK (import_status IN ('success', 'failed', 'partial')),
    error_message TEXT,
    imported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin actions log
CREATE TABLE admin_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES users(id),
    action_type TEXT NOT NULL, -- 'delete_recipe', 'delete_user', 'ban_user', etc.
    target_type TEXT NOT NULL, -- 'recipe', 'user', 'review'
    target_id UUID NOT NULL,
    reason TEXT,
    metadata JSONB,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ANALYTICS (for admin dashboard)
-- ============================================

-- Platform-wide statistics
CREATE TABLE analytics_daily (
    date DATE PRIMARY KEY,
    total_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    total_recipes INTEGER DEFAULT 0,
    new_recipes INTEGER DEFAULT 0,
    public_recipes INTEGER DEFAULT 0,
    private_recipes INTEGER DEFAULT 0,
    total_favorites INTEGER DEFAULT 0,
    total_views INTEGER DEFAULT 0,
    api_imports INTEGER DEFAULT 0,
    scraped_imports INTEGER DEFAULT 0,
    manual_imports INTEGER DEFAULT 0,
    chat_sessions INTEGER DEFAULT 0,
    chat_messages INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User activity tracking (for analytics)
CREATE TABLE user_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL, -- 'view_recipe', 'create_recipe', 'favorite', etc.
    recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Recipe indexes
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_is_public ON recipes(is_public);
CREATE INDEX idx_recipes_is_deleted ON recipes(is_deleted);
CREATE INDEX idx_recipes_created_at ON recipes(created_at);
CREATE INDEX idx_recipes_title ON recipes(title);
CREATE INDEX idx_recipes_cuisine_type ON recipes(cuisine_type);
CREATE INDEX idx_recipes_meal_type ON recipes(meal_type);
CREATE INDEX idx_recipes_source_type ON recipes(source_type);
CREATE INDEX idx_recipes_spoonacular_id ON recipes(spoonacular_id);

-- Ingredient indexes
CREATE INDEX idx_ingredients_name ON ingredients(name);
CREATE INDEX idx_ingredients_category ON ingredients(category);
CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_ingredient_id ON recipe_ingredients(ingredient_id);

-- User interaction indexes
CREATE INDEX idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_user_favorites_recipe_id ON user_favorites(recipe_id);
CREATE INDEX idx_collections_user_id ON collections(user_id);
CREATE INDEX idx_recipe_reviews_recipe_id ON recipe_reviews(recipe_id);
CREATE INDEX idx_recipe_reviews_user_id ON recipe_reviews(user_id);

-- Chat indexes
CREATE INDEX idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX idx_chat_conversations_session_id ON chat_conversations(session_id);
CREATE INDEX idx_chat_conversations_expires_at ON chat_conversations(expires_at);
CREATE INDEX idx_chat_messages_conversation_id ON chat_messages(conversation_id);

-- Activity indexes
CREATE INDEX idx_user_activity_log_user_id ON user_activity_log(user_id);
CREATE INDEX idx_user_activity_log_created_at ON user_activity_log(created_at);
CREATE INDEX idx_admin_actions_admin_id ON admin_actions(admin_id);
CREATE INDEX idx_admin_actions_performed_at ON admin_actions(performed_at);

-- Tag indexes
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_recipe_tags_recipe_id ON recipe_tags(recipe_id);
CREATE INDEX idx_recipe_tags_tag_id ON recipe_tags(tag_id);

-- Full-text search
CREATE INDEX idx_recipes_search ON recipes USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));
CREATE INDEX idx_users_search ON users USING gin(to_tsvector('english', username || ' ' || COALESCE(full_name, '')));

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Recipe policies
CREATE POLICY "Public recipes are viewable by everyone" 
    ON recipes FOR SELECT 
    USING (is_public = true AND is_deleted = false);

CREATE POLICY "Users can view their own recipes" 
    ON recipes FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own recipes" 
    ON recipes FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own recipes" 
    ON recipes FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recipes" 
    ON recipes FOR DELETE 
    USING (auth.uid() = user_id);

-- Admin can see and modify everything
CREATE POLICY "Admins can do anything with recipes" 
    ON recipes 
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Favorites policies
CREATE POLICY "Users can manage their own favorites" 
    ON user_favorites 
    USING (auth.uid() = user_id);

-- Collections policies
CREATE POLICY "Users can manage their own collections" 
    ON collections 
    USING (auth.uid() = user_id);

CREATE POLICY "Public collections are viewable by everyone" 
    ON collections FOR SELECT 
    USING (is_public = true);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_collections_updated_at BEFORE UPDATE ON collections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Increment favorite count
CREATE OR REPLACE FUNCTION increment_favorite_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE recipes 
    SET favorite_count = favorite_count + 1 
    WHERE id = NEW.recipe_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER on_favorite_added AFTER INSERT ON user_favorites
    FOR EACH ROW EXECUTE FUNCTION increment_favorite_count();

-- Decrement favorite count
CREATE OR REPLACE FUNCTION decrement_favorite_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE recipes 
    SET favorite_count = favorite_count - 1 
    WHERE id = OLD.recipe_id;
    RETURN OLD;
END;
$$ language 'plpgsql';

CREATE TRIGGER on_favorite_removed AFTER DELETE ON user_favorites
    FOR EACH ROW EXECUTE FUNCTION decrement_favorite_count();

-- Clean up expired guest chat conversations
CREATE OR REPLACE FUNCTION delete_expired_guest_chats()
RETURNS void AS $$
BEGIN
    DELETE FROM chat_conversations 
    WHERE user_id IS NULL 
    AND expires_at < NOW();
END;
$$ language 'plpgsql';

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Insert sample tags
INSERT INTO tags (name, category) VALUES
('vegetarian', 'dietary'),
('vegan', 'dietary'),
('gluten-free', 'dietary'),
('dairy-free', 'dietary'),
('keto', 'dietary'),
('paleo', 'dietary'),
('low-carb', 'dietary'),
('high-protein', 'dietary'),
('quick', 'cooking-method'),
('one-pot', 'cooking-method'),
('slow-cooker', 'cooking-method'),
('instant-pot', 'cooking-method'),
('no-cook', 'cooking-method'),
('meal-prep', 'occasion'),
('comfort-food', 'occasion'),
('healthy', 'dietary'),
('budget-friendly', 'occasion'),
('kid-friendly', 'occasion'),
('date-night', 'occasion'),
('party', 'occasion');

-- Insert sample ingredients
INSERT INTO ingredients (name, category, common_unit, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g) VALUES
('Chicken Breast', 'proteins', 'oz', 165, 31, 3.6, 0, 0),
('Ground Beef', 'proteins', 'oz', 250, 26, 15, 0, 0),
('Salmon', 'proteins', 'oz', 208, 20, 13, 0, 0),
('Eggs', 'proteins', 'large', 155, 13, 11, 1.1, 0),
('Onion', 'vegetables', 'medium', 40, 1.1, 0.1, 9.3, 1.7),
('Garlic', 'vegetables', 'clove', 149, 6.4, 0.5, 33, 2.1),
('Tomato', 'vegetables', 'medium', 18, 0.9, 0.2, 3.9, 1.2),
('Bell Pepper', 'vegetables', 'medium', 31, 1, 0.3, 6, 2.1),
('Broccoli', 'vegetables', 'cup', 55, 3.7, 0.6, 11, 2.4),
('Spinach', 'vegetables', 'cup', 23, 2.9, 0.4, 3.6, 2.2),
('Rice', 'grains', 'cup', 130, 2.7, 0.3, 28, 0.4),
('Pasta', 'grains', 'oz', 371, 13, 1.5, 75, 3.2),
('Olive Oil', 'fats', 'tablespoon', 884, 0, 100, 0, 0),
('Butter', 'fats', 'tablespoon', 717, 0.9, 81, 0.1, 0),
('Salt', 'seasonings', 'teaspoon', 0, 0, 0, 0, 0),
('Black Pepper', 'seasonings', 'teaspoon', 251, 10.4, 3.3, 64, 25),
('Milk', 'dairy', 'cup', 61, 3.2, 3.3, 4.8, 0),
('Cheese', 'dairy', 'oz', 402, 25, 33, 1.3, 0);