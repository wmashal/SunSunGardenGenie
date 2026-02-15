-- 1. Wipe the old placeholder items cleanly
TRUNCATE TABLE products;

-- 2. Insert your 3 specific custom links
INSERT INTO products (name, category, description, dimensions, color, thumbnail_url, ai_tags)
VALUES 
(
    'Premium Garden Tile', 'Hardscape', 'High-quality outdoor surface material for patios.', 'Custom Area', 'Natural Stone', 
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTJwr3A_fGx0JNMvzeXQbZV4ViBZXTsxCTyeQ&s', array['tile', 'patio', 'stone']
),
(
    'Tall Wooden Planter', 'Decor', 'Elegant vertical planter for outdoor spaces.', 'Large', 'Warm Wood', 
    'https://static.wixstatic.com/media/5ef4ca_4f4204662a874ffab67ba2a416024c55~mv2.jpg/v1/fill/w_568,h_1004,al_c,q_85,usm_0.66_1.00_0.01,enc_avif,quality_auto/5ef4ca_4f4204662a874ffab67ba2a416024c55~mv2.jpg', array['planter', 'wood', 'tall']
),
(
    'Rattan Garden Seating', 'Furniture', 'Comfortable outdoor seating for relaxing in the yard.', 'Standard Set', 'Grey', 
    'https://www.coopersofstortford.co.uk/images/products/medium/XGB83i.jpg', array['furniture', 'seating', 'relax']
);