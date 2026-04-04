-- 1. Enable pgvector extension for future AI Semantic Search
create extension if not exists vector;

-- 2. Create the core Inventory/Products table
create table if not exists products (
    id uuid default gen_random_uuid() primary key,
    name text not null,
    category text not null,       -- e.g., 'Plant', 'Hardscape', 'Furniture', 'Appliance'
    description text,             -- Full product description
    dimensions text,              -- e.g., '60x60 cm' or '1.5m height'
    color text,                   -- e.g., 'Crimson Red', 'Slate Grey'
    thumbnail_url text,           -- URL to your product image
    ai_tags text[],               -- Array of tags: e.g., {'zen', 'drought-tolerant'}
    embedding vector(768),        -- The AI vector representation of this product
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Security: Enable Row Level Security (RLS)
alter table products enable row level security;

create policy "Products are viewable by everyone."
    on products for select
    using ( true );

-- 4. Seed Data: Unified Master Catalog
insert into products (name, category, description, dimensions, color, thumbnail_url, ai_tags)
values
(
    'Artificial Grass Turf', 'Hardscape', 'Premium artificial grass mat for outdoor patios and garden areas. Shown with rattan furniture on top.', 'Custom Area', 'Green',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTJwr3A_fGx0JNMvzeXQbZV4ViBZXTsxCTyeQ&s', array['grass', 'turf', 'artificial', 'patio']
),
(
    'Bird of Paradise Planter', 'Decor', 'Large bird-of-paradise plant in a ribbed cream oval pot. Tropical statement piece for patios.', '1.2m Height', 'Green / Cream Pot',
    'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcS9L_bT75Wf0gMQdVlpdxGk0l6HG5qanpK5sy29o_MtYFtUWl4HBXgdXu6BjBszIOGEs0lNkbOj1jd9PtT0k9EZ8KCohgd2kSWgVwZ1EKaRWfU6HwAUWv0FOIG_pz6Ao87Ik6cP5K76&usqp=CAc', array['plant', 'tropical', 'planter', 'pot']
),
(
    'Stone Flower Pot Set', 'Decor', 'Set of 3 stone-effect embossed grey pots with colorful seasonal flowers. Classic garden styling.', 'Small / Medium / Large', 'Stone Grey',
    'https://www.coopersofstortford.co.uk/images/products/medium/XGB83i.jpg', array['pot', 'flower', 'stone', 'planter']
),
(
    'Black Rattan Bistro Set', 'Furniture', '2-chair rattan bistro set with glass-top coffee table. Black weave with beige seat cushions.', '2 Chairs + Table', 'Black / Beige',
    'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcQqq4PVAFWbhI38PSaVNny8Uxl4pacoq4SajUyzOpSBVRj_12dbZfiPp_Uy7i8am_gMO9iFoMZVHb0x62p40bLQ0hP83TgEmRzXuqFc6nI', array['rattan', 'bistro', 'chairs', 'furniture']
),
(
    'Brown Rattan Bistro Set', 'Furniture', '2-chair rattan bistro set with glass-top coffee table. Brown weave with navy blue cushions.', '2 Chairs + Table', 'Brown / Navy',
    'https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcSOdwbEubOUvBZwUgnPeRb5CseYQztrO11tzCVCdNrMtpyaKzj50Kdd3zNGKIRsXydnrR5liUHfb2G5my4CS8-M3G9q3WUgANnkuUN979xhbTN3USzuXqFsAg', array['rattan', 'bistro', 'chairs', 'furniture']
),
(
    'Rattan Lounge Sofa Set', 'Furniture', 'Full rattan outdoor lounge set: loveseat, 2 armchairs, and glass-top coffee table. Black weave with cream cushions.', '5-Piece Set', 'Black / Cream',
    'https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcTd-70slyr5nPpzfFVa8T3lfq6uOzHKXyHhZZjf5CeT3CVD09IltGt7i6YubNeN2WaY7h8MOJtoWX5GBmk1C5Iz_q7TfXSVvZ4Ox6G7cEtbLYgXQxxKh5LzeLg', array['rattan', 'sofa', 'lounge', 'furniture']
),
(
    'Decorative Maple Tree', 'Plant', 'Tall decorative maple-style tree with green and red foliage in a white square planter pot.', '1.8m Height', 'Green / White Pot',
    'https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcQi2P82qHSAeL-Z4a2mnmDCrA9ifFJN4AIk4xlvuyuJTDqfSwwNvk-CqjbUAzKtJmxLisjXipd9WHrTfXYaHWU1ikbA1vI63aki8i9BRsjP5DeN2NGjRFjKBlXY85BHVV-0Dy4GPA&usqp=CA', array['tree', 'maple', 'decorative', 'plant']
),
(
    'Bird of Paradise (Large)', 'Plant', 'Extra-large bird-of-paradise plant in a tall ribbed cream pot. Bold tropical focal point.', '1.5m Height', 'Green / Cream Pot',
    'https://www.betili-shop.com/media/catalog/product/cache/cd5c75df12a522c856c0ce13fcf27ab6/1/0/104407.png', array['plant', 'tropical', 'bird of paradise', 'pot']
),
(
    'White Garden Pergola', 'Structure', 'Large white vinyl pergola with open lattice roof. Provides shade and structure for outdoor dining areas.', '4m x 4m', 'White',
    'https://encrypted-tbn2.gstatic.com/shopping?q=tbn:ANd9GcR0dcEC-lknDx4-bqdGgUX6D3fckZex1lmdEQkByuZ4F5rQLATxEy_jMvS_qOFdxIqpVIZOcO3DdWG5vKjjomY_haf2k9YBHQ', array['pergola', 'shade', 'structure', 'white']
);