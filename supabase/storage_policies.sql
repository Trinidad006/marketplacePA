-- =====================================================
-- Script para configurar políticas RLS de Storage
-- Para el bucket: product-images
-- =====================================================
-- IMPORTANTE: Este script debe ejecutarse desde el SQL Editor
-- en el dashboard de Supabase después de crear el bucket

-- Primero, asegúrate de que el bucket existe y es público
-- Si no existe, créalo desde el dashboard de Supabase:
-- Storage > New bucket > product-images (público)

-- =====================================================
-- Políticas para product-images bucket
-- =====================================================

-- 1. Política INSERT: Permitir a usuarios autenticados subir imágenes
--    Solo pueden subir en su propia carpeta (user_id/)
CREATE POLICY "Users can upload product images in their own folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Política SELECT: Permitir lectura pública de todas las imágenes
CREATE POLICY "Public can view product images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- 3. Política DELETE: Solo el dueño puede eliminar sus propias imágenes
CREATE POLICY "Users can delete their own product images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Política UPDATE: Solo el dueño puede actualizar sus propias imágenes
CREATE POLICY "Users can update their own product images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- Políticas para avatars bucket (opcional, si lo necesitas)
-- =====================================================

-- 1. Política INSERT: Usuarios autenticados pueden subir su propio avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  name = (auth.uid()::text || '.jpg')
);

-- 2. Política SELECT: Lectura pública de avatares
CREATE POLICY "Public can view avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- 3. Política DELETE: Solo el dueño puede eliminar su avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  name = (auth.uid()::text || '.jpg')
);

-- 4. Política UPDATE: Solo el dueño puede actualizar su avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  name = (auth.uid()::text || '.jpg')
)
WITH CHECK (
  bucket_id = 'avatars' AND
  name = (auth.uid()::text || '.jpg')
);

