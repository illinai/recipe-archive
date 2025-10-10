ALTER TABLE recipe_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own reviews" 
    ON recipe_reviews 
    USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view reviews on public recipes" 
    ON recipe_reviews FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM recipes 
            WHERE recipes.id = recipe_reviews.recipe_id 
            AND recipes.is_public = true
        )
    );

CREATE POLICY "Users can view their own activity" 
    ON user_activity_log FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Only admins can view admin actions" 
    ON admin_actions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Only admins can log actions" 
    ON admin_actions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );