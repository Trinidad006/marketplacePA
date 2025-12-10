-- =====================================================
-- Script para agregar productos de prueba
-- Para la cuenta: tridad.eps@gmail.com
-- =====================================================

-- Primero, obtener el ID del usuario y asegurarse de que sea vendedor
DO $$
DECLARE
    user_id_var UUID;
BEGIN
    -- Buscar el usuario por email
    SELECT id INTO user_id_var
    FROM auth.users
    WHERE email = 'tridad.eps@gmail.com';
    
    IF user_id_var IS NULL THEN
        RAISE EXCEPTION 'Usuario con email tridad.eps@gmail.com no encontrado';
    END IF;
    
    -- Asegurarse de que el usuario tenga rol de vendedor
    UPDATE public.user_profiles
    SET role = 'seller'
    WHERE id = user_id_var;
    
    -- Si no existe el perfil, crearlo
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE id = user_id_var) THEN
        INSERT INTO public.user_profiles (id, role, full_name)
        VALUES (user_id_var, 'seller', 'Trini');
    END IF;
    
    -- Insertar productos de prueba con imágenes de ejemplo
    -- Nota: Las imágenes usan URLs de placeholder. Puedes reemplazarlas después con imágenes reales
    INSERT INTO public.products (
        seller_id,
        name,
        description,
        price,
        category,
        stock,
        images,
        is_featured,
        views_count,
        created_at,
        updated_at
    ) VALUES
    (
        user_id_var,
        'Jarrón de Cerámica Artesanal',
        'Hermoso jarrón de cerámica hecho a mano con técnicas tradicionales. Perfecto para decorar cualquier espacio con un toque único y artesanal. Cada pieza es única y está cuidadosamente elaborada por artesanos expertos.',
        450.00,
        'Cerámica',
        5,
        ARRAY[
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=800&fit=crop&auto=format&q=80'
        ]::TEXT[],
        false,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Bufanda de Alpaca Tejida',
        'Bufanda suave y cálida tejida a mano con lana de alpaca de alta calidad. Ideal para los días fríos, combina estilo y comodidad. Disponible en varios colores naturales que complementan cualquier outfit.',
        280.00,
        'Textiles',
        8,
        ARRAY[
            'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=800&h=800&fit=crop&auto=format&q=80'
        ]::TEXT[],
        false,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Collar de Plata con Piedras Semipreciosas',
        'Elegante collar de plata 925 con piedras semipreciosas naturales. Diseño único que combina la belleza de la naturaleza con la artesanía fina. Perfecto para ocasiones especiales o uso diario.',
        650.00,
        'Joyería',
        3,
        ARRAY[
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop&auto=format&q=80',
            'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&h=800&fit=crop'
        ]::TEXT[],
        true,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Caja de Madera Tallada a Mano',
        'Caja de madera de cedro tallada artesanalmente con motivos tradicionales. Perfecta para guardar objetos especiales o como pieza decorativa. Cada caja es única y muestra el trabajo detallado del artesano.',
        320.00,
        'Madera',
        6,
        ARRAY[
            'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&h=800&fit=crop&auto=format&q=80'
        ]::TEXT[],
        false,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Vaso de Vidrio Soplado',
        'Vaso único de vidrio soplado a mano con colores vibrantes. Cada pieza es una obra de arte única, creada por maestros vidrieros. Perfecto para bebidas o como elemento decorativo.',
        180.00,
        'Vidrio',
        10,
        ARRAY[
            'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=800&h=800&fit=crop&auto=format&q=80'
        ]::TEXT[],
        false,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Bolso de Cuero Genuino',
        'Bolso de cuero genuino hecho a mano con atención al detalle. Diseño clásico y elegante que combina funcionalidad con estilo. Perfecto para uso diario o ocasiones especiales.',
        520.00,
        'Cuero',
        4,
        ARRAY[
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&h=800&fit=crop&auto=format&q=80',
            'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=800&h=800&fit=crop'
        ]::TEXT[],
        true,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Escultura en Metal Reciclado',
        'Escultura moderna creada con metal reciclado, mostrando la creatividad y el compromiso con el medio ambiente. Pieza única que añade un toque contemporáneo a cualquier espacio.',
        750.00,
        'Metal',
        2,
        ARRAY[
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800&h=800&fit=crop&auto=format&q=80'
        ]::TEXT[],
        true,
        0,
        NOW(),
        NOW()
    ),
    (
        user_id_var,
        'Cuadro de Acuarela Original',
        'Pintura original en acuarela que captura la belleza de la naturaleza. Obra única del artista, perfecta para decorar espacios interiores con un toque artístico y personal.',
        380.00,
        'Pintura',
        1,
        ARRAY[
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=800&fit=crop',
            'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=800&fit=crop&auto=format&q=80'
        ]::TEXT[],
        false,
        0,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE 'Productos agregados exitosamente para el usuario: %', user_id_var;
END $$;

