-- 1. Enable pgvector extension for future AI Semantic Search
create extension if not exists vector;

-- 2. Create the core Inventory/Products table
create table if not exists products (
    id uuid default gen_random_uuid() primary key,
    name text not null,
    category text not null,       -- e.g., 'Plant', 'Hardscape', 'Furniture'
    description text,             -- Full product description
    dimensions text,              -- e.g., '60x60 cm' or '1.5m height'
    color text,                   -- e.g., 'Crimson Red', 'Slate Grey'
    thumbnail_url text,           -- URL to your Supabase Storage image
    ai_tags text[],               -- Array of tags: e.g., {'zen', 'drought-tolerant'}
    embedding vector(768),        -- The AI vector representation of this product
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Security: Enable Row Level Security (RLS)
alter table products enable row level security;

create policy "Products are viewable by everyone."
    on products for select
    using ( true );

-- 4. Seed Data: Updated with your custom product images
insert into products (name, category, description, dimensions, color, thumbnail_url, ai_tags)
values
(
    'Premium Garden Tile', 'Hardscape', 'High-quality outdoor surface material for modern patios.', 'Custom Area', 'Natural Stone',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTJwr3A_fGx0JNMvzeXQbZV4ViBZXTsxCTyeQ&s', array['tile', 'patio', 'stone']
),
(
    'Tall Wooden Planter', 'Decor', 'Elegant vertical planter for outdoor accenting.', 'Large', 'Warm Wood',
    'https://static.wixstatic.com/media/5ef4ca_4f4204662a874ffab67ba2a416024c55~mv2.jpg/v1/fill/w_568,h_1004,al_c,q_85,usm_0.66_1.00_0.01,enc_avif,quality_auto/5ef4ca_4f4204662a874ffab67ba2a416024c55~mv2.jpg', array['planter', 'wood', 'tall']
),
(
    'Rattan Garden Seating', 'Furniture', 'Comfortable grey wicker seating for relaxing in the yard.', 'Standard Set', 'Grey',
    'https://www.coopersofstortford.co.uk/images/products/medium/XGB83i.jpg', array['furniture', 'seating', 'relax']
);