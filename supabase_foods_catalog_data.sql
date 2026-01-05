-- ============================================
-- CoTrainr Foods Catalog - Comprehensive Indian Foods
-- ============================================
-- Run this after running supabase_meal_tracker_schema.sql
-- ============================================

BEGIN;

-- Clear existing data (optional - remove if you want to keep existing)
-- DELETE FROM public.foods_catalog;

-- ============================================
-- SOUTH INDIAN BREAKFAST (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Idli', 'pcs', 50, 106, 3.5, 25.0, 0.5, 1.2, 0, 10, 1.2, 20, 50, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Dosa', 'pcs', 120, 160, 2.5, 30.0, 5.0, 1.5, 2, 15, 1.5, 30, 100, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Vada', 'pcs', 60, 220, 4.5, 35.0, 8.0, 2.0, 1, 20, 1.8, 25, 120, ARRAY['South Indian', 'Breakfast', 'Snacks'], TRUE),
  ('Upma', 'bowl', 200, 180, 3.0, 28.0, 6.0, 1.8, 2, 25, 1.2, 15, 80, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Pongal', 'bowl', 250, 190, 4.0, 32.0, 5.0, 2.0, 1, 20, 1.5, 30, 100, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Uttapam', 'pcs', 150, 170, 3.5, 32.0, 4.5, 2.0, 2, 18, 1.6, 35, 110, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Appam', 'pcs', 100, 140, 2.8, 28.0, 3.0, 1.5, 3, 12, 1.0, 25, 70, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Pesarattu', 'pcs', 80, 135, 5.0, 22.0, 3.5, 4.0, 1, 15, 2.0, 50, 200, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Rava Idli', 'pcs', 55, 115, 3.0, 26.0, 1.5, 1.0, 2, 12, 1.0, 18, 45, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Medu Vada', 'pcs', 60, 215, 4.0, 34.0, 7.5, 2.0, 1, 22, 1.8, 24, 115, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Masala Dosa', 'pcs', 150, 200, 4.0, 35.0, 6.5, 2.0, 3, 25, 1.8, 40, 130, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Rava Dosa', 'pcs', 130, 175, 3.0, 32.0, 5.5, 1.8, 2, 20, 1.6, 35, 110, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Onion Dosa', 'pcs', 140, 180, 3.5, 33.0, 5.8, 1.8, 2, 22, 1.7, 38, 120, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Set Dosa', 'pcs', 50, 155, 3.0, 28.0, 4.5, 1.5, 2, 18, 1.4, 32, 95, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Rava Upma', 'bowl', 200, 185, 3.5, 30.0, 6.5, 2.0, 2, 28, 1.4, 18, 85, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Vermicelli Upma', 'bowl', 200, 195, 3.8, 32.0, 6.8, 1.8, 3, 30, 1.5, 20, 90, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Poha', 'bowl', 200, 150, 3.5, 30.0, 3.0, 2.0, 2, 20, 1.8, 15, 120, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Sabudana Khichdi', 'bowl', 200, 220, 1.5, 45.0, 5.0, 1.0, 1, 25, 1.0, 10, 50, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Aloo Paratha', 'pcs', 100, 280, 7.0, 42.0, 10.0, 3.0, 2, 18, 2.5, 35, 380, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Gobi Paratha', 'pcs', 100, 260, 7.5, 40.0, 9.0, 3.5, 3, 20, 2.2, 40, 320, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Methi Paratha', 'pcs', 90, 270, 8.0, 41.0, 9.5, 4.0, 2, 16, 3.5, 45, 350, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Paneer Paratha', 'pcs', 100, 320, 12.0, 38.0, 14.0, 2.5, 2, 20, 2.0, 180, 120, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Besan Chilla', 'pcs', 80, 180, 7.0, 25.0, 5.0, 3.5, 2, 15, 2.5, 50, 280, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Moong Dal Chilla', 'pcs', 80, 160, 8.0, 22.0, 4.5, 4.0, 1, 12, 2.8, 55, 300, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('French Toast', 'pcs', 60, 220, 8.0, 25.0, 9.0, 1.2, 8, 280, 1.5, 80, 120, ARRAY['Breakfast'], TRUE),
  ('Sandwich', 'pcs', 100, 250, 10.0, 35.0, 8.0, 2.5, 4, 450, 2.0, 120, 180, ARRAY['Breakfast', 'Snacks'], TRUE),
  ('Toast', 'pcs', 30, 265, 9.0, 49.0, 3.2, 2.7, 3, 490, 3.6, 54, 107, ARRAY['Breakfast'], TRUE),
  ('Cornflakes', 'bowl', 50, 379, 7.0, 84.0, 0.4, 3.0, 10, 729, 28.9, 12, 168, ARRAY['Breakfast'], TRUE),
  ('Oats', 'bowl', 100, 389, 17.0, 66.0, 7.0, 11.0, 1, 2, 4.7, 54, 429, ARRAY['Breakfast'], TRUE),
  ('Porridge', 'bowl', 200, 120, 3.0, 25.0, 2.0, 2.5, 3, 5, 1.2, 20, 150, ARRAY['Breakfast'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- NORTH INDIAN BREADS
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Roti', 'pcs', 35, 260, 9.0, 50.0, 2.0, 2.5, 0, 8, 2.5, 20, 150, ARRAY['North Indian'], TRUE),
  ('Chapati', 'pcs', 40, 270, 10.0, 48.0, 2.5, 2.8, 0, 10, 2.8, 25, 160, ARRAY['North Indian'], TRUE),
  ('Naan', 'pcs', 90, 280, 8.0, 52.0, 6.0, 2.0, 2, 520, 2.0, 30, 140, ARRAY['North Indian'], TRUE),
  ('Paratha', 'pcs', 80, 320, 7.5, 45.0, 12.0, 2.2, 1, 15, 2.2, 28, 150, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Puri', 'pcs', 25, 350, 6.0, 42.0, 18.0, 1.5, 1, 12, 1.8, 15, 100, ARRAY['North Indian', 'Breakfast'], TRUE),
  ('Bhatura', 'pcs', 100, 320, 8.0, 48.0, 10.0, 2.0, 2, 500, 2.0, 35, 130, ARRAY['North Indian'], TRUE),
  ('Kulcha', 'pcs', 85, 295, 8.5, 50.0, 7.0, 2.5, 3, 480, 2.2, 32, 145, ARRAY['North Indian'], TRUE),
  ('Tandoori Roti', 'pcs', 45, 275, 9.5, 49.0, 3.0, 2.8, 0, 12, 2.8, 26, 155, ARRAY['North Indian'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- PROTEINS - VEGETARIAN
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Paneer', 'g', 1, 265, 18.0, 2.0, 20.0, 0, 0, 15, 0.2, 200, 50, ARRAY['North Indian', 'Protein', 'Veg'], TRUE),
  ('Dal', 'bowl', 150, 120, 7.0, 20.0, 2.0, 5.0, 1, 350, 2.5, 40, 300, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Chana Masala', 'bowl', 200, 160, 9.0, 25.0, 4.0, 6.0, 3, 400, 3.0, 60, 350, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Rajma', 'bowl', 200, 150, 8.5, 22.0, 3.5, 5.5, 2, 380, 2.8, 50, 320, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Moong Dal', 'bowl', 150, 110, 7.5, 18.0, 1.5, 5.5, 1, 300, 2.0, 45, 280, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Toor Dal', 'bowl', 150, 125, 8.0, 22.0, 2.5, 5.0, 2, 320, 2.2, 50, 310, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Urad Dal', 'bowl', 150, 130, 8.5, 20.0, 3.0, 5.5, 1, 340, 2.5, 55, 330, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Paneer Butter Masala', 'bowl', 200, 250, 12.0, 10.0, 18.0, 1.0, 5, 450, 0.8, 150, 120, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Palak Paneer', 'bowl', 200, 180, 10.0, 8.0, 12.0, 2.5, 3, 400, 2.5, 180, 250, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Shahi Paneer', 'bowl', 200, 280, 11.0, 12.0, 20.0, 1.5, 6, 480, 0.9, 160, 130, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Chole', 'bowl', 200, 165, 9.5, 26.0, 4.5, 6.5, 3, 420, 3.2, 65, 360, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Aloo Gobi', 'bowl', 200, 95, 2.5, 18.0, 2.0, 4.0, 4, 350, 1.2, 45, 420, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Bhindi Masala', 'bowl', 200, 85, 3.0, 12.0, 3.0, 5.0, 5, 400, 1.5, 80, 350, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Baingan Bharta', 'bowl', 200, 105, 3.5, 15.0, 4.0, 6.0, 6, 380, 1.0, 25, 300, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Aloo Matar', 'bowl', 200, 110, 4.0, 20.0, 2.5, 5.0, 5, 360, 1.5, 50, 380, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- PROTEINS - NON-VEGETARIAN
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Egg', 'pcs', 50, 155, 13.0, 1.1, 11.0, 0, 0.7, 124, 1.8, 56, 138, ARRAY['Protein', 'Non veg', 'Breakfast'], TRUE),
  ('Chicken Breast', 'g', 1, 165, 31.0, 0.0, 3.6, 0, 0, 74, 0.9, 15, 256, ARRAY['Protein', 'Non veg'], TRUE),
  ('Chicken Curry', 'bowl', 200, 200, 15.0, 8.0, 12.0, 1.5, 3, 450, 1.5, 30, 200, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Butter Chicken', 'bowl', 200, 320, 18.0, 12.0, 22.0, 1.0, 8, 550, 1.2, 35, 220, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Tikka Masala', 'bowl', 200, 285, 20.0, 10.0, 18.0, 1.5, 6, 520, 1.4, 32, 210, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Biryani', 'bowl', 250, 350, 18.0, 45.0, 12.0, 2.0, 3, 600, 2.0, 55, 250, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Mutton Curry', 'bowl', 200, 280, 22.0, 6.0, 18.0, 1.0, 2, 500, 2.5, 25, 280, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Fish Curry', 'bowl', 200, 180, 18.0, 6.0, 10.0, 1.0, 2, 450, 1.2, 80, 280, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Prawn Curry', 'bowl', 200, 150, 20.0, 5.0, 6.0, 0.5, 2, 500, 1.5, 100, 250, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Egg Curry', 'bowl', 200, 180, 12.0, 8.0, 10.0, 1.5, 3, 400, 2.0, 80, 200, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- RICE DISHES (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Plain Rice', 'bowl', 150, 130, 2.7, 28.0, 0.3, 0.4, 0, 5, 0.8, 10, 35, ARRAY['Lunch', 'Dinner'], TRUE),
  ('Biryani', 'bowl', 250, 300, 8.0, 45.0, 12.0, 2.0, 2, 600, 2.0, 50, 200, ARRAY['North Indian', 'Lunch', 'Dinner'], TRUE),
  ('Fried Rice', 'bowl', 200, 230, 4.0, 38.0, 8.0, 1.5, 2, 400, 1.0, 20, 100, ARRAY['Lunch', 'Dinner'], TRUE),
  ('Curd Rice', 'bowl', 200, 170, 3.5, 32.0, 4.0, 1.0, 4, 200, 0.5, 120, 150, ARRAY['South Indian', 'Lunch', 'Dinner'], TRUE),
  ('Lemon Rice', 'bowl', 200, 200, 3.0, 35.0, 6.0, 1.2, 1, 350, 0.8, 15, 80, ARRAY['South Indian', 'Lunch', 'Dinner'], TRUE),
  ('Tamatar Rice', 'bowl', 200, 195, 3.2, 34.0, 5.5, 1.5, 4, 320, 0.9, 20, 95, ARRAY['South Indian', 'Lunch', 'Dinner'], TRUE),
  ('Jeera Rice', 'bowl', 200, 185, 3.0, 33.0, 4.0, 1.0, 0, 250, 0.7, 12, 70, ARRAY['North Indian', 'Lunch', 'Dinner'], TRUE),
  ('Pulao', 'bowl', 200, 220, 4.5, 40.0, 6.0, 2.0, 2, 380, 1.2, 25, 120, ARRAY['North Indian', 'Lunch', 'Dinner'], TRUE),
  ('Veg Pulao', 'bowl', 200, 225, 4.8, 41.0, 6.5, 2.5, 3, 400, 1.5, 30, 150, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Peas Pulao', 'bowl', 200, 215, 5.2, 40.0, 6.2, 3.0, 2, 390, 1.8, 35, 180, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Mushroom Pulao', 'bowl', 200, 210, 5.5, 39.0, 5.8, 2.2, 2, 385, 1.6, 28, 170, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Coconut Rice', 'bowl', 200, 240, 3.5, 36.0, 9.0, 2.0, 3, 280, 1.0, 18, 120, ARRAY['South Indian', 'Lunch', 'Dinner'], TRUE),
  ('Tomato Rice', 'bowl', 200, 200, 3.5, 35.0, 6.5, 2.0, 5, 340, 1.0, 22, 110, ARRAY['South Indian', 'Lunch', 'Dinner'], TRUE),
  ('Schezwan Rice', 'bowl', 200, 245, 4.5, 42.0, 7.5, 2.5, 4, 650, 1.5, 25, 140, ARRAY['Indo-Chinese', 'Lunch', 'Dinner'], TRUE),
  ('Khichdi', 'bowl', 250, 140, 5.0, 25.0, 2.5, 3.0, 1, 350, 2.0, 30, 200, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Dal Khichdi', 'bowl', 250, 145, 6.0, 26.0, 2.8, 3.5, 1, 360, 2.5, 40, 250, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Brown Rice', 'bowl', 150, 111, 2.6, 23.0, 0.9, 1.8, 0, 5, 0.8, 10, 43, ARRAY['Lunch', 'Dinner'], TRUE),
  ('Basmati Rice', 'bowl', 150, 130, 2.7, 28.0, 0.3, 0.4, 0, 5, 0.8, 10, 35, ARRAY['Lunch', 'Dinner'], TRUE)
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================
-- FRUITS
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Banana', 'pcs', 120, 89, 1.1, 23.0, 0.3, 2.6, 12, 1, 0.3, 5, 358, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Apple', 'pcs', 150, 52, 0.3, 14.0, 0.2, 2.4, 10, 1, 0.1, 6, 107, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Mango', 'pcs', 200, 60, 0.8, 15.0, 0.4, 1.6, 14, 1, 0.2, 10, 168, ARRAY['Fruits'], TRUE),
  ('Orange', 'pcs', 150, 47, 0.9, 12.0, 0.1, 2.4, 9, 0, 0.1, 40, 181, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Pomegranate', 'bowl', 150, 83, 1.7, 19.0, 1.2, 4.0, 14, 3, 0.3, 10, 236, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Guava', 'pcs', 100, 68, 2.6, 14.0, 1.0, 5.4, 9, 2, 0.3, 18, 417, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Papaya', 'bowl', 150, 43, 0.5, 11.0, 0.3, 1.7, 8, 8, 0.3, 20, 182, ARRAY['Fruits'], TRUE),
  ('Watermelon', 'bowl', 150, 30, 0.6, 8.0, 0.2, 0.4, 6, 1, 0.2, 7, 112, ARRAY['Fruits'], TRUE),
  ('Grapes', 'bowl', 150, 69, 0.7, 18.0, 0.2, 0.9, 16, 3, 0.4, 10, 191, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Pineapple', 'bowl', 150, 50, 0.5, 13.0, 0.1, 1.4, 10, 1, 0.3, 13, 109, ARRAY['Fruits'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- DAIRY
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Milk', 'ml', 1, 42, 3.4, 5.0, 1.0, 0, 5, 44, 0.0, 113, 150, ARRAY['Dairy'], TRUE),
  ('Curd/Yogurt', 'bowl', 200, 59, 10.0, 3.6, 0.4, 0, 4, 36, 0.1, 110, 141, ARRAY['Dairy'], TRUE),
  ('Buttermilk', 'ml', 1, 38, 3.3, 4.8, 1.0, 0, 5, 105, 0.0, 116, 151, ARRAY['Dairy'], TRUE),
  ('Paneer', 'g', 1, 265, 18.0, 2.0, 20.0, 0, 0, 15, 0.2, 200, 50, ARRAY['Dairy', 'Protein'], TRUE),
  ('Ghee', 'tsp', 5, 900, 0.0, 0.0, 100.0, 0, 0, 0, 0.0, 0, 0, ARRAY['Dairy'], TRUE),
  ('Cheese', 'g', 1, 350, 25.0, 1.0, 27.0, 0, 1, 621, 0.7, 721, 76, ARRAY['Dairy'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- SNACKS & STREET FOOD (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Samosa', 'pcs', 60, 280, 4.5, 35.0, 14.0, 2.5, 2, 450, 1.8, 30, 200, ARRAY['Snacks', 'Street food'], TRUE),
  ('Pakora', 'pcs', 40, 230, 5.0, 28.0, 11.0, 3.0, 2, 380, 2.0, 45, 250, ARRAY['Snacks', 'Street food'], TRUE),
  ('Vada Pav', 'pcs', 150, 285, 8.0, 42.0, 11.0, 3.5, 3, 550, 2.2, 85, 320, ARRAY['Snacks', 'Street food'], TRUE),
  ('Pav Bhaji', 'plate', 350, 250, 6.0, 38.0, 9.0, 4.0, 8, 650, 2.5, 80, 450, ARRAY['Snacks', 'Street food'], TRUE),
  ('Chole Bhature', 'plate', 400, 320, 10.0, 48.0, 12.0, 5.0, 4, 700, 3.0, 90, 380, ARRAY['Snacks', 'Street food'], TRUE),
  ('Dahi Puri', 'plate', 200, 180, 4.0, 32.0, 5.0, 2.5, 6, 400, 1.2, 120, 200, ARRAY['Snacks', 'Street food'], TRUE),
  ('Pani Puri', 'plate', 150, 120, 2.5, 25.0, 2.0, 2.0, 4, 300, 1.0, 40, 150, ARRAY['Snacks', 'Street food'], TRUE),
  ('Bhel Puri', 'bowl', 200, 160, 4.5, 30.0, 4.5, 3.0, 5, 450, 2.0, 60, 280, ARRAY['Snacks', 'Street food'], TRUE),
  ('Kachori', 'pcs', 50, 280, 5.0, 38.0, 12.0, 2.0, 2, 420, 1.8, 35, 180, ARRAY['Snacks', 'Street food'], TRUE),
  ('Dhokla', 'pcs', 80, 135, 5.5, 22.0, 3.0, 2.5, 3, 380, 1.5, 55, 200, ARRAY['Snacks'], TRUE),
  ('Khandvi', 'bowl', 150, 125, 5.0, 20.0, 3.5, 2.0, 2, 350, 1.2, 50, 180, ARRAY['Snacks'], TRUE),
  ('Aloo Tikki', 'pcs', 80, 180, 3.5, 28.0, 7.0, 3.5, 2, 350, 1.5, 40, 420, ARRAY['Snacks', 'Street food'], TRUE),
  ('Chaat', 'plate', 200, 180, 4.0, 30.0, 6.0, 3.0, 6, 450, 1.5, 70, 300, ARRAY['Snacks', 'Street food'], TRUE),
  ('Sev Puri', 'plate', 180, 165, 3.5, 28.0, 5.5, 2.5, 5, 420, 1.3, 65, 280, ARRAY['Snacks', 'Street food'], TRUE),
  ('Ragda Pattice', 'plate', 300, 220, 6.5, 35.0, 7.5, 4.5, 4, 500, 2.0, 85, 400, ARRAY['Snacks', 'Street food'], TRUE),
  ('Dahi Vada', 'plate', 200, 195, 5.5, 30.0, 6.5, 2.0, 8, 380, 1.2, 130, 250, ARRAY['Snacks', 'Street food'], TRUE),
  ('Aloo Chaat', 'plate', 200, 150, 3.0, 25.0, 5.0, 3.5, 4, 400, 1.5, 50, 450, ARRAY['Snacks', 'Street food'], TRUE),
  ('Bhajiya', 'pcs', 30, 250, 4.0, 30.0, 12.0, 2.5, 2, 400, 1.8, 40, 220, ARRAY['Snacks', 'Street food'], TRUE),
  ('Cutlet', 'pcs', 80, 220, 6.0, 25.0, 10.0, 2.5, 2, 450, 1.5, 50, 300, ARRAY['Snacks'], TRUE),
  ('Spring Roll', 'pcs', 50, 200, 4.5, 28.0, 8.0, 2.0, 3, 420, 1.2, 35, 180, ARRAY['Snacks'], TRUE),
  ('Momos', 'pcs', 30, 120, 4.0, 18.0, 3.5, 1.5, 1, 350, 1.0, 25, 150, ARRAY['Snacks'], TRUE),
  ('Noodles', 'bowl', 200, 220, 5.0, 38.0, 6.0, 2.0, 2, 600, 1.5, 30, 200, ARRAY['Snacks', 'Street food'], TRUE),
  ('Fried Rice', 'bowl', 200, 230, 4.0, 38.0, 8.0, 1.5, 2, 400, 1.0, 20, 100, ARRAY['Snacks', 'Street food'], TRUE),
  ('Maggi', 'bowl', 200, 380, 9.0, 58.0, 12.0, 2.5, 2, 1200, 3.5, 25, 150, ARRAY['Snacks'], TRUE),
  ('Biscuit', 'pcs', 10, 480, 7.0, 68.0, 20.0, 2.0, 20, 500, 2.5, 50, 100, ARRAY['Snacks'], TRUE),
  ('Namkeen', 'bowl', 50, 520, 12.0, 55.0, 28.0, 3.0, 2, 1200, 3.0, 80, 200, ARRAY['Snacks'], TRUE),
  ('Chips', 'bowl', 50, 536, 7.0, 53.0, 35.0, 4.0, 0.2, 8, 1.0, 12, 1275, ARRAY['Snacks'], TRUE),
  ('Peanuts', 'bowl', 50, 567, 26.0, 16.0, 49.0, 8.5, 4.0, 18, 4.6, 92, 705, ARRAY['Snacks'], TRUE),
  ('Almonds', 'bowl', 50, 579, 21.0, 22.0, 50.0, 12.5, 4.4, 1, 3.7, 269, 733, ARRAY['Snacks'], TRUE),
  ('Cashews', 'bowl', 50, 553, 18.0, 30.0, 44.0, 3.3, 5.9, 12, 6.7, 37, 660, ARRAY['Snacks'], TRUE),
  ('Raisins', 'bowl', 50, 299, 3.1, 79.0, 0.5, 3.7, 59, 11, 1.9, 50, 749, ARRAY['Snacks'], TRUE),
  ('Dates', 'pcs', 7, 282, 2.5, 75.0, 0.4, 8.0, 63, 1, 1.0, 39, 656, ARRAY['Snacks'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- DRINKS & BEVERAGES
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Water', 'ml', 1, 0, 0.0, 0.0, 0.0, 0, 0, 7, 0.0, 7, 0, ARRAY['Drinks'], TRUE),
  ('Lassi', 'ml', 1, 65, 2.0, 8.0, 2.5, 0, 7, 40, 0.0, 100, 120, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Mango Lassi', 'ml', 1, 85, 2.0, 12.0, 2.5, 0.5, 11, 35, 0.1, 95, 130, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Chai/Tea', 'cup', 200, 30, 0.5, 6.0, 0.5, 0, 5, 10, 0.1, 20, 50, ARRAY['Drinks'], TRUE),
  ('Coffee', 'cup', 200, 5, 0.3, 0.0, 0.0, 0, 0, 5, 0.0, 5, 92, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Orange)', 'ml', 1, 45, 0.7, 10.0, 0.2, 0.2, 9, 1, 0.1, 11, 200, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Apple)', 'ml', 1, 46, 0.2, 11.0, 0.1, 0.2, 10, 4, 0.1, 8, 107, ARRAY['Drinks'], TRUE),
  ('Tender Coconut Water', 'ml', 1, 19, 0.7, 4.0, 0.2, 0, 3, 105, 0.0, 24, 250, ARRAY['Drinks'], TRUE),
  ('Lemonade', 'ml', 1, 25, 0.1, 6.0, 0.0, 0, 6, 5, 0.0, 6, 90, ARRAY['Drinks'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- VEGETABLES (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Potato', 'g', 1, 77, 2.0, 17.0, 0.1, 2.2, 0.8, 6, 0.8, 12, 421, ARRAY['Veg'], TRUE),
  ('Onion', 'g', 1, 40, 1.1, 9.3, 0.1, 1.7, 4.2, 4, 0.2, 23, 146, ARRAY['Veg'], TRUE),
  ('Tomato', 'g', 1, 18, 0.9, 3.9, 0.2, 1.2, 2.6, 5, 0.3, 10, 237, ARRAY['Veg'], TRUE),
  ('Carrot', 'g', 1, 41, 0.9, 10.0, 0.2, 2.8, 4.7, 69, 0.3, 33, 320, ARRAY['Veg'], TRUE),
  ('Capsicum', 'g', 1, 20, 1.0, 4.6, 0.2, 1.5, 2.4, 4, 0.3, 10, 175, ARRAY['Veg'], TRUE),
  ('Cauliflower', 'g', 1, 25, 1.9, 5.0, 0.3, 2.0, 1.9, 30, 0.4, 22, 299, ARRAY['Veg'], TRUE),
  ('Cabbage', 'g', 1, 25, 1.3, 5.8, 0.1, 2.5, 3.2, 18, 0.5, 40, 170, ARRAY['Veg'], TRUE),
  ('Spinach', 'g', 1, 23, 2.9, 3.6, 0.4, 2.2, 0.4, 79, 2.7, 99, 558, ARRAY['Veg'], TRUE),
  ('Okra/Bhindi', 'g', 1, 33, 1.9, 7.0, 0.2, 3.2, 1.5, 7, 0.3, 82, 299, ARRAY['Veg'], TRUE),
  ('Brinjal/Eggplant', 'g', 1, 25, 1.0, 6.0, 0.2, 3.0, 3.5, 2, 0.2, 9, 229, ARRAY['Veg'], TRUE),
  ('Beans', 'g', 1, 31, 1.8, 7.0, 0.1, 2.7, 3.3, 6, 1.0, 37, 211, ARRAY['Veg'], TRUE),
  ('Peas', 'g', 1, 81, 5.4, 14.0, 0.4, 5.1, 5.7, 5, 1.5, 25, 244, ARRAY['Veg'], TRUE),
  ('Bottle Gourd', 'g', 1, 15, 0.6, 3.4, 0.1, 0.5, 2.5, 2, 0.2, 26, 150, ARRAY['Veg'], TRUE),
  ('Ridge Gourd', 'g', 1, 20, 0.5, 4.0, 0.2, 1.0, 2.0, 3, 0.3, 20, 140, ARRAY['Veg'], TRUE),
  ('Bitter Gourd', 'g', 1, 17, 1.0, 4.0, 0.2, 2.8, 0, 5, 0.4, 19, 296, ARRAY['Veg'], TRUE),
  ('Cucumber', 'g', 1, 16, 0.7, 4.0, 0.1, 0.5, 1.7, 2, 0.3, 16, 147, ARRAY['Veg'], TRUE),
  ('Radish', 'g', 1, 16, 0.7, 3.4, 0.1, 1.6, 1.9, 39, 0.3, 25, 233, ARRAY['Veg'], TRUE),
  ('Beetroot', 'g', 1, 43, 1.6, 10.0, 0.2, 2.8, 7.0, 78, 0.8, 16, 325, ARRAY['Veg'], TRUE),
  ('Sweet Potato', 'g', 1, 86, 1.6, 20.0, 0.1, 3.0, 4.2, 54, 0.6, 30, 337, ARRAY['Veg'], TRUE),
  ('Yam', 'g', 1, 118, 1.5, 28.0, 0.2, 4.1, 0.5, 9, 0.5, 17, 816, ARRAY['Veg'], TRUE),
  ('Ladies Finger', 'g', 1, 33, 1.9, 7.0, 0.2, 3.2, 1.5, 7, 0.3, 82, 299, ARRAY['Veg'], TRUE),
  ('Drumstick', 'g', 1, 37, 2.1, 8.5, 0.2, 3.2, 0, 42, 0.4, 30, 461, ARRAY['Veg'], TRUE),
  ('Pumpkin', 'g', 1, 26, 1.0, 7.0, 0.1, 0.5, 2.8, 1, 0.8, 21, 340, ARRAY['Veg'], TRUE),
  ('Zucchini', 'g', 1, 17, 1.2, 3.1, 0.3, 1.0, 2.5, 8, 0.4, 16, 261, ARRAY['Veg'], TRUE),
  ('Broccoli', 'g', 1, 34, 2.8, 7.0, 0.4, 2.6, 1.5, 33, 0.7, 47, 316, ARRAY['Veg'], TRUE),
  ('Mushroom', 'g', 1, 22, 3.1, 3.3, 0.3, 1.0, 2.0, 5, 0.5, 3, 318, ARRAY['Veg'], TRUE),
  ('Corn', 'g', 1, 86, 3.3, 19.0, 1.2, 2.7, 3.2, 15, 0.5, 2, 270, ARRAY['Veg'], TRUE),
  ('Green Chilli', 'g', 1, 40, 2.0, 9.0, 0.2, 1.5, 5.3, 7, 1.0, 18, 322, ARRAY['Veg'], TRUE),
  ('Ginger', 'g', 1, 80, 1.8, 18.0, 0.8, 2.0, 1.7, 13, 0.6, 16, 415, ARRAY['Veg'], TRUE),
  ('Garlic', 'g', 1, 149, 6.4, 33.0, 0.5, 2.1, 1.0, 17, 1.7, 181, 401, ARRAY['Veg'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- FRUITS (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Banana', 'pcs', 120, 89, 1.1, 23.0, 0.3, 2.6, 12, 1, 0.3, 5, 358, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Apple', 'pcs', 150, 52, 0.3, 14.0, 0.2, 2.4, 10, 1, 0.1, 6, 107, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Mango', 'pcs', 200, 60, 0.8, 15.0, 0.4, 1.6, 14, 1, 0.2, 10, 168, ARRAY['Fruits'], TRUE),
  ('Orange', 'pcs', 150, 47, 0.9, 12.0, 0.1, 2.4, 9, 0, 0.1, 40, 181, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Pomegranate', 'bowl', 150, 83, 1.7, 19.0, 1.2, 4.0, 14, 3, 0.3, 10, 236, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Guava', 'pcs', 100, 68, 2.6, 14.0, 1.0, 5.4, 9, 2, 0.3, 18, 417, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Papaya', 'bowl', 150, 43, 0.5, 11.0, 0.3, 1.7, 8, 8, 0.3, 20, 182, ARRAY['Fruits'], TRUE),
  ('Watermelon', 'bowl', 150, 30, 0.6, 8.0, 0.2, 0.4, 6, 1, 0.2, 7, 112, ARRAY['Fruits'], TRUE),
  ('Grapes', 'bowl', 150, 69, 0.7, 18.0, 0.2, 0.9, 16, 3, 0.4, 10, 191, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Pineapple', 'bowl', 150, 50, 0.5, 13.0, 0.1, 1.4, 10, 1, 0.3, 13, 109, ARRAY['Fruits'], TRUE),
  ('Strawberry', 'bowl', 150, 32, 0.7, 7.7, 0.3, 2.0, 4.9, 1, 0.4, 16, 153, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Kiwi', 'pcs', 75, 61, 1.1, 15.0, 0.5, 3.0, 9, 3, 0.3, 34, 312, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Pear', 'pcs', 180, 57, 0.4, 15.0, 0.1, 3.1, 10, 1, 0.2, 9, 116, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Peach', 'pcs', 150, 39, 0.9, 9.5, 0.3, 1.5, 8.4, 0, 0.3, 6, 190, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Plum', 'pcs', 70, 46, 0.7, 11.0, 0.3, 1.4, 9.9, 0, 0.2, 6, 157, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Cherry', 'bowl', 150, 63, 1.0, 16.0, 0.2, 2.1, 12.8, 0, 0.4, 13, 222, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Blueberry', 'bowl', 150, 57, 0.7, 14.0, 0.3, 2.4, 10, 1, 0.3, 6, 77, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Raspberry', 'bowl', 150, 52, 1.2, 12.0, 0.7, 6.5, 4.4, 1, 0.7, 25, 151, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Blackberry', 'bowl', 150, 43, 1.4, 10.0, 0.5, 5.3, 4.9, 1, 0.6, 29, 162, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Custard Apple', 'pcs', 200, 101, 1.7, 25.0, 0.6, 2.4, 0, 4, 0.6, 30, 382, ARRAY['Fruits'], TRUE),
  ('Sapota/Chikoo', 'pcs', 170, 83, 0.4, 20.0, 1.1, 5.3, 0, 12, 0.8, 21, 193, ARRAY['Fruits'], TRUE),
  ('Jackfruit', 'bowl', 150, 95, 1.7, 24.0, 0.6, 1.5, 19, 2, 0.6, 24, 448, ARRAY['Fruits'], TRUE),
  ('Dragon Fruit', 'pcs', 227, 60, 1.2, 13.0, 0.4, 3.0, 7.7, 0, 0.7, 18, 264, ARRAY['Fruits'], TRUE),
  ('Lychee', 'pcs', 10, 66, 0.8, 17.0, 0.4, 1.3, 15, 1, 0.3, 5, 171, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Muskmelon', 'bowl', 150, 34, 0.8, 8.0, 0.2, 0.9, 7.9, 16, 0.2, 9, 267, ARRAY['Fruits'], TRUE),
  ('Dates', 'pcs', 7, 282, 2.5, 75.0, 0.4, 8.0, 63, 1, 1.0, 39, 656, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Fig', 'pcs', 50, 74, 0.8, 19.0, 0.3, 2.9, 16, 1, 0.4, 35, 232, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Jamun', 'bowl', 100, 60, 0.7, 15.0, 0.2, 0.6, 0, 26, 0.2, 19, 79, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Amla', 'pcs', 20, 44, 0.9, 10.0, 0.6, 4.3, 0, 1, 0.3, 25, 198, ARRAY['Fruits'], TRUE),
  ('Wood Apple', 'pcs', 100, 97, 2.5, 22.0, 0.3, 5.1, 0, 13, 0.6, 61, 600, ARRAY['Fruits'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- NON-VEGETARIAN (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Egg', 'pcs', 50, 155, 13.0, 1.1, 11.0, 0, 0.7, 124, 1.8, 56, 138, ARRAY['Protein', 'Non veg', 'Breakfast'], TRUE),
  ('Chicken Breast', 'g', 1, 165, 31.0, 0.0, 3.6, 0, 0, 74, 0.9, 15, 256, ARRAY['Protein', 'Non veg'], TRUE),
  ('Chicken Thigh', 'g', 1, 209, 26.0, 0.0, 10.9, 0, 0, 95, 0.9, 10, 259, ARRAY['Protein', 'Non veg'], TRUE),
  ('Chicken Drumstick', 'g', 1, 172, 28.0, 0.0, 5.7, 0, 0, 88, 0.9, 12, 250, ARRAY['Protein', 'Non veg'], TRUE),
  ('Chicken Wings', 'g', 1, 203, 30.0, 0.0, 8.1, 0, 0, 82, 0.9, 13, 252, ARRAY['Protein', 'Non veg'], TRUE),
  ('Chicken Curry', 'bowl', 200, 200, 15.0, 8.0, 12.0, 1.5, 3, 450, 1.5, 30, 200, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Butter Chicken', 'bowl', 200, 320, 18.0, 12.0, 22.0, 1.0, 8, 550, 1.2, 35, 220, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Tikka Masala', 'bowl', 200, 285, 20.0, 10.0, 18.0, 1.5, 6, 520, 1.4, 32, 210, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Biryani', 'bowl', 250, 350, 18.0, 45.0, 12.0, 2.0, 3, 600, 2.0, 55, 250, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Korma', 'bowl', 200, 295, 19.0, 11.0, 20.0, 1.2, 7, 540, 1.3, 34, 225, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Do Pyaza', 'bowl', 200, 210, 16.0, 9.0, 12.5, 1.8, 4, 480, 1.6, 32, 230, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken Kadai', 'bowl', 200, 225, 17.0, 8.5, 14.0, 1.6, 3, 460, 1.5, 31, 215, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Chicken 65', 'bowl', 200, 280, 22.0, 12.0, 16.0, 1.0, 4, 650, 1.8, 28, 240, ARRAY['North Indian', 'Protein', 'Non veg', 'Snacks'], TRUE),
  ('Chicken Tikka', 'bowl', 200, 195, 25.0, 3.0, 8.0, 0.5, 2, 420, 1.2, 20, 280, ARRAY['North Indian', 'Protein', 'Non veg', 'Snacks'], TRUE),
  ('Mutton Curry', 'bowl', 200, 280, 22.0, 6.0, 18.0, 1.0, 2, 500, 2.5, 25, 280, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Mutton Biryani', 'bowl', 250, 380, 24.0, 46.0, 15.0, 2.2, 3, 650, 2.8, 60, 300, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Mutton Korma', 'bowl', 200, 310, 23.0, 8.0, 22.0, 1.2, 3, 550, 2.6, 28, 290, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Mutton Rogan Josh', 'bowl', 200, 295, 21.0, 7.0, 20.0, 1.5, 2, 520, 2.4, 26, 275, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Fish Curry', 'bowl', 200, 180, 18.0, 6.0, 10.0, 1.0, 2, 450, 1.2, 80, 280, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Fish Fry', 'pcs', 100, 195, 22.0, 8.0, 8.5, 0.5, 1, 480, 1.0, 45, 350, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Fish Biryani', 'bowl', 250, 320, 20.0, 44.0, 9.0, 1.8, 2, 580, 1.5, 85, 320, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Prawn Curry', 'bowl', 200, 150, 20.0, 5.0, 6.0, 0.5, 2, 500, 1.5, 100, 250, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Prawn Fry', 'bowl', 200, 180, 24.0, 8.0, 6.5, 0.3, 1, 520, 1.8, 120, 280, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Crab Curry', 'bowl', 200, 140, 19.0, 4.0, 5.5, 0.4, 2, 480, 1.2, 95, 270, ARRAY['South Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Egg Curry', 'bowl', 200, 180, 12.0, 8.0, 10.0, 1.5, 3, 400, 2.0, 80, 200, ARRAY['North Indian', 'Protein', 'Non veg', 'Lunch', 'Dinner'], TRUE),
  ('Egg Bhurji', 'bowl', 200, 195, 13.5, 6.0, 13.0, 1.2, 2, 420, 2.2, 85, 210, ARRAY['North Indian', 'Protein', 'Non veg', 'Breakfast'], TRUE),
  ('Omelette', 'pcs', 100, 154, 11.0, 1.1, 11.0, 0, 0.7, 124, 1.8, 56, 138, ARRAY['Protein', 'Non veg', 'Breakfast'], TRUE),
  ('Boiled Egg', 'pcs', 50, 155, 13.0, 1.1, 11.0, 0, 0.7, 124, 1.8, 56, 138, ARRAY['Protein', 'Non veg', 'Breakfast'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- VEGETARIAN DISHES (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Paneer', 'g', 1, 265, 18.0, 2.0, 20.0, 0, 0, 15, 0.2, 200, 50, ARRAY['North Indian', 'Protein', 'Veg'], TRUE),
  ('Dal', 'bowl', 150, 120, 7.0, 20.0, 2.0, 5.0, 1, 350, 2.5, 40, 300, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Chana Masala', 'bowl', 200, 160, 9.0, 25.0, 4.0, 6.0, 3, 400, 3.0, 60, 350, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Rajma', 'bowl', 200, 150, 8.5, 22.0, 3.5, 5.5, 2, 380, 2.8, 50, 320, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Moong Dal', 'bowl', 150, 110, 7.5, 18.0, 1.5, 5.5, 1, 300, 2.0, 45, 280, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Toor Dal', 'bowl', 150, 125, 8.0, 22.0, 2.5, 5.0, 2, 320, 2.2, 50, 310, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Urad Dal', 'bowl', 150, 130, 8.5, 20.0, 3.0, 5.5, 1, 340, 2.5, 55, 330, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Paneer Butter Masala', 'bowl', 200, 250, 12.0, 10.0, 18.0, 1.0, 5, 450, 0.8, 150, 120, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Palak Paneer', 'bowl', 200, 180, 10.0, 8.0, 12.0, 2.5, 3, 400, 2.5, 180, 250, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Shahi Paneer', 'bowl', 200, 280, 11.0, 12.0, 20.0, 1.5, 6, 480, 0.9, 160, 130, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Paneer Tikka', 'bowl', 200, 220, 15.0, 8.0, 14.0, 1.2, 3, 420, 1.0, 180, 140, ARRAY['North Indian', 'Protein', 'Veg', 'Snacks'], TRUE),
  ('Paneer Kadai', 'bowl', 200, 195, 12.5, 9.0, 13.0, 1.8, 4, 440, 0.9, 165, 135, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Paneer Do Pyaza', 'bowl', 200, 210, 13.0, 10.0, 14.5, 2.0, 5, 460, 0.9, 170, 145, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Chole', 'bowl', 200, 165, 9.5, 26.0, 4.5, 6.5, 3, 420, 3.2, 65, 360, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Aloo Gobi', 'bowl', 200, 95, 2.5, 18.0, 2.0, 4.0, 4, 350, 1.2, 45, 420, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Bhindi Masala', 'bowl', 200, 85, 3.0, 12.0, 3.0, 5.0, 5, 400, 1.5, 80, 350, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Baingan Bharta', 'bowl', 200, 105, 3.5, 15.0, 4.0, 6.0, 6, 380, 1.0, 25, 300, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Aloo Matar', 'bowl', 200, 110, 4.0, 20.0, 2.5, 5.0, 5, 360, 1.5, 50, 380, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Mix Veg', 'bowl', 200, 100, 3.0, 16.0, 3.0, 4.5, 5, 380, 1.8, 55, 400, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Jeera Aloo', 'bowl', 200, 120, 2.8, 20.0, 3.5, 3.5, 3, 370, 1.3, 40, 450, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Aloo Jeera', 'bowl', 200, 115, 2.5, 19.0, 3.0, 3.2, 2, 360, 1.2, 38, 440, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Gobi Manchurian', 'bowl', 200, 180, 4.5, 28.0, 7.0, 3.5, 6, 650, 1.5, 50, 380, ARRAY['Indo-Chinese', 'Veg', 'Snacks'], TRUE),
  ('Paneer Manchurian', 'bowl', 200, 250, 14.0, 18.0, 14.0, 1.5, 5, 680, 1.2, 200, 150, ARRAY['Indo-Chinese', 'Veg', 'Snacks'], TRUE),
  ('Veg Manchurian', 'bowl', 200, 160, 5.0, 25.0, 5.5, 4.0, 7, 620, 1.8, 60, 400, ARRAY['Indo-Chinese', 'Veg', 'Snacks'], TRUE),
  ('Dal Makhani', 'bowl', 200, 200, 9.0, 24.0, 8.0, 6.0, 2, 420, 3.5, 65, 380, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Dal Tadka', 'bowl', 200, 140, 8.0, 22.0, 3.5, 5.5, 2, 400, 2.8, 55, 350, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Sambar', 'bowl', 200, 90, 4.0, 15.0, 2.5, 3.5, 3, 450, 1.8, 45, 280, ARRAY['South Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Rasam', 'bowl', 200, 35, 1.5, 6.0, 0.8, 1.2, 2, 380, 0.8, 20, 150, ARRAY['South Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Kadhi', 'bowl', 200, 120, 5.0, 18.0, 3.5, 2.0, 4, 450, 0.8, 120, 200, ARRAY['North Indian', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Rajma Masala', 'bowl', 200, 155, 8.8, 23.0, 3.8, 5.8, 2, 390, 2.9, 52, 330, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Chana Dal', 'bowl', 150, 140, 8.5, 24.0, 3.0, 6.0, 3, 350, 3.5, 70, 380, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE),
  ('Masoor Dal', 'bowl', 150, 116, 9.0, 20.0, 0.4, 7.6, 1, 280, 7.6, 19, 369, ARRAY['North Indian', 'Protein', 'Veg', 'Lunch', 'Dinner'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- DAIRY (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Milk', 'ml', 1, 42, 3.4, 5.0, 1.0, 0, 5, 44, 0.0, 113, 150, ARRAY['Dairy'], TRUE),
  ('Curd/Yogurt', 'bowl', 200, 59, 10.0, 3.6, 0.4, 0, 4, 36, 0.1, 110, 141, ARRAY['Dairy'], TRUE),
  ('Buttermilk', 'ml', 1, 38, 3.3, 4.8, 1.0, 0, 5, 105, 0.0, 116, 151, ARRAY['Dairy'], TRUE),
  ('Paneer', 'g', 1, 265, 18.0, 2.0, 20.0, 0, 0, 15, 0.2, 200, 50, ARRAY['Dairy', 'Protein'], TRUE),
  ('Ghee', 'tsp', 5, 900, 0.0, 0.0, 100.0, 0, 0, 0, 0.0, 0, 0, ARRAY['Dairy'], TRUE),
  ('Cheese', 'g', 1, 350, 25.0, 1.0, 27.0, 0, 1, 621, 0.7, 721, 76, ARRAY['Dairy'], TRUE),
  ('Butter', 'tsp', 5, 717, 0.9, 0.1, 81.0, 0, 0, 11, 0.0, 24, 24, ARRAY['Dairy'], TRUE),
  ('Cream', 'ml', 1, 345, 2.1, 2.8, 37.0, 0, 2.9, 27, 0.0, 65, 76, ARRAY['Dairy'], TRUE),
  ('Ice Cream', 'bowl', 100, 207, 3.5, 24.0, 11.0, 0.7, 21, 80, 0.1, 128, 199, ARRAY['Dairy', 'Snacks'], TRUE),
  ('Khoya', 'g', 1, 300, 15.0, 25.0, 20.0, 0, 0, 50, 0.3, 500, 200, ARRAY['Dairy'], TRUE),
  ('Cottage Cheese', 'g', 1, 98, 11.0, 3.4, 4.3, 0, 2.7, 364, 0.0, 83, 104, ARRAY['Dairy', 'Protein'], TRUE),
  ('Sour Cream', 'tsp', 15, 198, 1.7, 4.6, 19.4, 0, 3.1, 15, 0.0, 30, 61, ARRAY['Dairy'], TRUE),
  ('Yogurt Drink', 'ml', 1, 59, 1.7, 11.0, 0.4, 0, 10, 36, 0.0, 100, 141, ARRAY['Dairy', 'Drinks'], TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- DRINKS & BEVERAGES (EXPANDED)
-- ============================================
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, sodium_per_100g, iron_per_100g, calcium_per_100g, potassium_per_100g, tags, is_verified) VALUES
  ('Water', 'ml', 1, 0, 0.0, 0.0, 0.0, 0, 0, 7, 0.0, 7, 0, ARRAY['Drinks'], TRUE),
  ('Lassi', 'ml', 1, 65, 2.0, 8.0, 2.5, 0, 7, 40, 0.0, 100, 120, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Mango Lassi', 'ml', 1, 85, 2.0, 12.0, 2.5, 0.5, 11, 35, 0.1, 95, 130, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Chai/Tea', 'cup', 200, 30, 0.5, 6.0, 0.5, 0, 5, 10, 0.1, 20, 50, ARRAY['Drinks'], TRUE),
  ('Coffee', 'cup', 200, 5, 0.3, 0.0, 0.0, 0, 0, 5, 0.0, 5, 92, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Orange)', 'ml', 1, 45, 0.7, 10.0, 0.2, 0.2, 9, 1, 0.1, 11, 200, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Apple)', 'ml', 1, 46, 0.2, 11.0, 0.1, 0.2, 10, 4, 0.1, 8, 107, ARRAY['Drinks'], TRUE),
  ('Tender Coconut Water', 'ml', 1, 19, 0.7, 4.0, 0.2, 0, 3, 105, 0.0, 24, 250, ARRAY['Drinks'], TRUE),
  ('Lemonade', 'ml', 1, 25, 0.1, 6.0, 0.0, 0, 6, 5, 0.0, 6, 90, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Pomegranate)', 'ml', 1, 83, 0.2, 19.0, 0.1, 0.1, 14, 3, 0.1, 10, 236, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Watermelon)', 'ml', 1, 30, 0.6, 8.0, 0.2, 0.1, 6, 1, 0.1, 7, 112, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Grape)', 'ml', 1, 69, 0.4, 18.0, 0.1, 0.1, 16, 3, 0.2, 10, 191, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Pineapple)', 'ml', 1, 50, 0.4, 13.0, 0.1, 0.1, 10, 1, 0.2, 13, 109, ARRAY['Drinks'], TRUE),
  ('Fresh Juice (Mango)', 'ml', 1, 60, 0.5, 15.0, 0.2, 0.1, 14, 1, 0.1, 10, 168, ARRAY['Drinks'], TRUE),
  ('Smoothie (Banana)', 'ml', 1, 89, 1.1, 23.0, 0.3, 2.6, 12, 1, 0.3, 5, 358, ARRAY['Drinks'], TRUE),
  ('Smoothie (Mixed Fruit)', 'ml', 1, 55, 0.8, 14.0, 0.2, 1.5, 11, 2, 0.2, 12, 180, ARRAY['Drinks'], TRUE),
  ('Milkshake (Chocolate)', 'ml', 1, 120, 3.5, 18.0, 4.0, 0.5, 16, 80, 0.3, 120, 200, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Milkshake (Vanilla)', 'ml', 1, 110, 3.2, 16.0, 3.5, 0.3, 14, 75, 0.2, 115, 190, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Milkshake (Strawberry)', 'ml', 1, 105, 3.0, 15.0, 3.2, 0.4, 13, 70, 0.2, 110, 185, ARRAY['Dairy', 'Drinks'], TRUE),
  ('Green Tea', 'cup', 200, 2, 0.2, 0.0, 0.0, 0, 0, 3, 0.0, 3, 8, ARRAY['Drinks'], TRUE),
  ('Black Tea', 'cup', 200, 2, 0.0, 0.3, 0.0, 0, 0, 3, 0.0, 0, 37, ARRAY['Drinks'], TRUE),
  ('Masala Chai', 'cup', 200, 45, 1.0, 8.0, 1.2, 0.2, 7, 12, 0.2, 25, 60, ARRAY['Drinks'], TRUE),
  ('Cold Coffee', 'cup', 200, 85, 2.5, 12.0, 2.8, 0.2, 10, 45, 0.2, 100, 180, ARRAY['Drinks'], TRUE),
  ('Nimbu Pani', 'ml', 1, 25, 0.1, 6.0, 0.0, 0, 6, 5, 0.0, 6, 90, ARRAY['Drinks'], TRUE),
  ('Aam Panna', 'ml', 1, 35, 0.3, 8.0, 0.1, 0.3, 7, 3, 0.1, 8, 120, ARRAY['Drinks'], TRUE),
  ('Jal Jeera', 'ml', 1, 15, 0.2, 3.5, 0.1, 0.2, 3, 8, 0.1, 12, 85, ARRAY['Drinks'], TRUE),
  ('Soda', 'ml', 1, 41, 0.0, 10.6, 0.0, 0, 10.6, 4, 0.0, 3, 1, ARRAY['Drinks'], TRUE),
  ('Cola', 'ml', 1, 42, 0.1, 10.6, 0.0, 0, 10.6, 4, 0.0, 1, 1, ARRAY['Drinks'], TRUE)
ON CONFLICT DO NOTHING;

COMMIT;



