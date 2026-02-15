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
-- We want the Flutter app to be able to READ the catalog without user login for the POC.
alter table products enable row level security;

create policy "Products are viewable by everyone."
    on products for select
    using ( true );

-- 4. Seed Data: Insert our Penpot Wireframe examples so we have something to test
insert into products (name, category, description, dimensions, color, thumbnail_url, ai_tags)
values
(
    'Granite Paver',
    'Hardscape',
    'Non-slip texture, perfect for pathways.',
    '60x60 cm',
    'Slate Grey',
    'https://via.placeholder.com/150/E8F5E9/4CAF50?text=Paver',
    array['modern', 'pathway', 'stone']
),
(
    'Japanese Maple',
    'Plant',
    'Prefers partial shade, moderate watering.',
    '1.5m height',
    'Crimson Red',
    'https://via.placeholder.com/150/E8F5E9/4CAF50?text=Maple',
    array['zen', 'tree', 'shade']
);