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
),
(
    'Citrus Tree (Hadar)', 'Plant', 'Fragrant evergreen tree with seasonal fruit.', '1.8m Height', 'Green',
    'https://sunsun.co.il/wp-content/uploads/2025/08/%D7%94%D7%93%D7%A8.png', array['fruit', 'fragrant', 'citrus']
),
(
    'Shaped Olive Tree', 'Plant', 'Mediterranean olive tree with a professionally shaped trunk.', '2m Height', 'Silver-Green',
    'https://sunsun.co.il/wp-content/uploads/2025/08/%D7%96%D7%99%D7%AA-%D7%9E%D7%A2%D7%95%D7%A6%D7%91.png', array['shaped', 'olive', 'luxury']
),
(
    'Pomegranate Tree', 'Plant', 'Ornamental and fruit-bearing tree with vibrant red flowers.', '1.5m Height', 'Green/Red',
    'https://sunsun.co.il/wp-content/uploads/2025/08/%D7%A8%D7%99%D7%9E%D7%95%D7%9F.png', array['fruit', 'ornamental', 'pomegranate']
),
(
    'Luxury Outdoor Grill', 'Appliance', 'High-end stainless steel grill for outdoor kitchens.', 'Large', 'Chrome',
    'https://www.payngo.co.il/cdn-cgi/image/format=auto,metadata=none,quality=90/media/New-Icons/Category-icons/N862t.png', array['grill', 'cooking', 'kitchen']
),
(
    'Designer Lounge Sofa', 'Furniture', 'Premium comfort with weather-resistant deep cushions.', '3-Seater', 'Cream',
    'https://www.betili-shop.com/media/catalog/product/cache/cd5c75df12a522c856c0ce13fcf27ab6/1/0/104407.png', array['sofa', 'lounge', 'betili']
),
(
    'Modern Patio Accent', 'Decor', 'Contemporary outdoor decorative piece.', 'Medium', 'Neutral',
    'https://img.kwcdn.com/product/fancy/c8a143e4-d054-4201-84b8-3c1b7a5045ad.jpg?imageView2/2/w/800/q/70/format/avif', array['accent', 'decor', 'modern']
);