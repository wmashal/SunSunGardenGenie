-- Insert your new high-end trees, furniture, and appliances
insert into products (name, category, description, dimensions, color, thumbnail_url, ai_tags)
values 
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
    'https://www.payngo.co.il/cdn-cgi/image/format=auto,metadata=none,quality=90/media/New-Icons/Category-icons/N862t.png', array['grill', 'cooking']
),
(
    'Designer Lounge Sofa', 'Furniture', 'Premium comfort with weather-resistant deep cushions.', '3-Seater', 'Cream', 
    'https://www.betili-shop.com/media/catalog/product/cache/cd5c75df12a522c856c0ce13fcf27ab6/1/0/104407.png', array['sofa', 'lounge', 'betili']
),
(
    'Modern Patio Accent', 'Decor', 'Contemporary outdoor decorative piece.', 'Medium', 'Neutral', 
    'https://img.kwcdn.com/product/fancy/c8a143e4-d054-4201-84b8-3c1b7a5045ad.jpg?imageView2/2/w/800/q/70/format/avif', array['accent', 'decor']
);