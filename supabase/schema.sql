-- =====================================================
-- ArtMarket - Esquema de Base de Datos Supabase
-- =====================================================

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLA: user_profiles
-- Perfiles de usuario (comprador o vendedor)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('buyer', 'seller')),
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);

-- RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Perfiles públicos para lectura"
    ON public.user_profiles FOR SELECT
    USING (true);

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

-- =====================================================
-- TRIGGER: Crear perfil automáticamente al registrar usuario
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, role, full_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que se ejecuta cuando se crea un nuevo usuario en auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- TABLA: products
-- Productos publicados por vendedores
-- =====================================================
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    seller_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL CHECK (char_length(description) >= 50),
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    category TEXT NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    images TEXT[] NOT NULL DEFAULT '{}',
    is_featured BOOLEAN NOT NULL DEFAULT false,
    views_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_products_seller_id ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_price ON public.products(price);
CREATE INDEX IF NOT EXISTS idx_products_views ON public.products(views_count DESC);

-- RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Productos públicos para lectura"
    ON public.products FOR SELECT
    USING (true);

CREATE POLICY "Vendedores pueden crear productos"
    ON public.products FOR INSERT
    WITH CHECK (
        auth.uid() = seller_id
        AND EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'seller'
        )
    );

CREATE POLICY "Vendedores pueden actualizar sus productos"
    ON public.products FOR UPDATE
    USING (auth.uid() = seller_id);

CREATE POLICY "Vendedores pueden eliminar sus productos"
    ON public.products FOR DELETE
    USING (auth.uid() = seller_id);

-- Función para incrementar vistas
CREATE OR REPLACE FUNCTION public.increment_product_views(product_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.products
    SET views_count = views_count + 1
    WHERE id = product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TABLA: favorites
-- Relación de favoritos entre usuarios y productos
-- =====================================================
CREATE TABLE IF NOT EXISTS public.favorites (
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    PRIMARY KEY (user_id, product_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_product_id ON public.favorites(product_id);

-- RLS
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Usuarios pueden ver sus favoritos"
    ON public.favorites FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden agregar favoritos"
    ON public.favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden eliminar sus favoritos"
    ON public.favorites FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- TABLA: conversations
-- Conversaciones de chat entre compradores y vendedores
-- =====================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE (buyer_id, product_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_conversations_buyer_id ON public.conversations(buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller_id ON public.conversations(seller_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON public.conversations(last_message_at DESC);

-- RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Participantes pueden ver sus conversaciones"
    ON public.conversations FOR SELECT
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Compradores pueden crear conversaciones"
    ON public.conversations FOR INSERT
    WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "Participantes pueden actualizar conversaciones"
    ON public.conversations FOR UPDATE
    USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- =====================================================
-- TABLA: messages
-- Mensajes de chat
-- =====================================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Participantes pueden ver mensajes de sus conversaciones"
    ON public.messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (buyer_id = auth.uid() OR seller_id = auth.uid())
        )
    );

CREATE POLICY "Participantes pueden enviar mensajes"
    ON public.messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (buyer_id = auth.uid() OR seller_id = auth.uid())
        )
    );

CREATE POLICY "Mensajes pueden ser marcados como leídos"
    ON public.messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (buyer_id = auth.uid() OR seller_id = auth.uid())
        )
    );

-- =====================================================
-- TRIGGER: Actualizar last_message en conversations
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        unread_count = unread_count + 1
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_insert
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_last_message();

-- =====================================================
-- STORAGE: Buckets para imágenes
-- =====================================================
-- Nota: Ejecutar desde el dashboard de Supabase
-- Crear bucket: product-images (público)
-- Crear bucket: avatars (público)

-- Política para product-images
-- INSERT: authenticated users
-- SELECT: public
-- DELETE: owner only (basado en path)

-- Política para avatars
-- INSERT: authenticated users (solo su propio avatar)
-- SELECT: public
-- UPDATE: owner only
-- DELETE: owner only

-- =====================================================
-- REALTIME: Habilitar para mensajes
-- =====================================================
-- Ejecutar desde el dashboard de Supabase:
-- 1. Ir a Database > Replication
-- 2. Habilitar realtime para las tablas: messages, conversations

-- O ejecutar:
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

