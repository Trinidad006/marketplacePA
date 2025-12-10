-- =====================================================
-- Script para actualizar productos existentes con imágenes
-- Para la cuenta: tridad.eps@gmail.com
-- =====================================================

DO $$
DECLARE
    user_id_var UUID;
    product_record RECORD;
    product_updates TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Buscar el usuario por email
    SELECT id INTO user_id_var
    FROM auth.users
    WHERE email = 'tridad.eps@gmail.com';
    
    IF user_id_var IS NULL THEN
        RAISE EXCEPTION 'Usuario con email tridad.eps@gmail.com no encontrado';
    END IF;
    
    -- Actualizar productos existentes con imágenes
    -- Jarrón de Cerámica
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=800&fit=crop&auto=format&q=80'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Jarrón de Cerámica Artesanal'
    AND images = ARRAY[]::TEXT[];
    
    -- Bufanda de Alpaca
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=800&h=800&fit=crop&auto=format&q=80'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Bufanda de Alpaca Tejida'
    AND images = ARRAY[]::TEXT[];
    
    -- Collar de Plata
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop&auto=format&q=80',
        'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&h=800&fit=crop'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Collar de Plata con Piedras Semipreciosas'
    AND images = ARRAY[]::TEXT[];
    
    -- Caja de Madera
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&h=800&fit=crop&auto=format&q=80'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Caja de Madera Tallada a Mano'
    AND images = ARRAY[]::TEXT[];
    
    -- Vaso de Vidrio
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1571875257727-256c39da42af?w=800&h=800&fit=crop&auto=format&q=80'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Vaso de Vidrio Soplado'
    AND images = ARRAY[]::TEXT[];
    
    -- Bolso de Cuero
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&h=800&fit=crop&auto=format&q=80',
        'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=800&h=800&fit=crop'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Bolso de Cuero Genuino'
    AND images = ARRAY[]::TEXT[];
    
    -- Escultura en Metal
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800&h=800&fit=crop&auto=format&q=80'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Escultura en Metal Reciclado'
    AND images = ARRAY[]::TEXT[];
    
    -- Cuadro de Acuarela
    UPDATE public.products
    SET images = ARRAY[
        'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=800&fit=crop',
        'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=800&fit=crop&auto=format&q=80'
    ]::TEXT[],
    updated_at = NOW()
    WHERE seller_id = user_id_var 
    AND name = 'Cuadro de Acuarela Original'
    AND images = ARRAY[]::TEXT[];
    
    -- Mostrar resumen
    SELECT COUNT(*) INTO product_record
    FROM public.products
    WHERE seller_id = user_id_var 
    AND array_length(images, 1) > 0;
    
    RAISE NOTICE 'Productos actualizados con imágenes: %', product_record;
    RAISE NOTICE 'Script ejecutado exitosamente';
END $$;

