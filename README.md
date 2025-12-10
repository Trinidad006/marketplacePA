# ArtMarket 🎨

**Marketplace de Productos Artesanales con Chat en Tiempo Real**

Una aplicación Flutter para conectar artesanos con compradores, permitiendo la publicación, exploración y compra de productos artesanales únicos.

## 📱 Capturas de Pantalla

*Próximamente*

## ✨ Características

### Autenticación Dual
- ✅ Registro como Comprador o Vendedor
- ✅ Verificación de email obligatoria
- ✅ Perfiles diferenciados según rol

### Gestión de Productos (Vendedores)
- ✅ CRUD completo de productos
- ✅ Upload de hasta 3 imágenes por producto
- ✅ Compresión automática de imágenes (máx 1MB)
- ✅ Marcar productos como destacados (máx 3)
- ✅ Estadísticas de vistas y favoritos

### Exploración y Búsqueda (Compradores)
- ✅ Feed principal con productos aleatorios
- ✅ Búsqueda por nombre con debounce (300ms)
- ✅ Filtros: categoría, rango de precio, solo disponibles
- ✅ Ordenamiento: recientes, precio, popularidad
- ✅ Galería de imágenes deslizable en detalle
- ✅ Infinite scroll con paginación de 20 items

### Sistema de Favoritos
- ✅ Agregar/quitar con animación de corazón
- ✅ Lista de productos favoritos
- ✅ Optimistic updates

### Chat en Tiempo Real
- ✅ Iniciar conversación desde producto
- ✅ Lista de conversaciones activas
- ✅ Mensajes en tiempo real con Supabase Realtime
- ✅ Indicador de mensajes no leídos
- ✅ Timestamps relativos

### Perfil de Vendedor
- ✅ Vista pública con productos
- ✅ Tiempo en plataforma
- ✅ Botón para contactar

## 🛠️ Tecnologías

| Tecnología | Uso |
|------------|-----|
| **Flutter 3.x** | Framework UI |
| **Provider** | Estado con ChangeNotifier |
| **go_router** | Navegación con shell routes |
| **Supabase** | Backend, Auth, Storage, Realtime |
| **Dio** | HTTP con retry policy |
| **cached_network_image** | Caché de imágenes |
| **Lottie** | Animaciones |

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/      # Constantes de la app
│   ├── models/         # Modelos de datos
│   ├── providers/      # Providers globales
│   ├── router/         # Configuración de rutas
│   ├── services/       # Servicios (Supabase, Dio, Storage)
│   ├── theme/          # Tema de la app
│   └── widgets/        # Widgets compartidos
├── features/
│   ├── auth/           # Autenticación
│   ├── products/       # Productos
│   ├── favorites/      # Favoritos
│   ├── chat/           # Chat
│   └── profile/        # Perfil
└── main.dart
```

## 🗄️ Base de Datos

### Tablas Supabase

- `user_profiles` - Perfiles de usuario
- `products` - Productos
- `favorites` - Favoritos (relación N:M)
- `conversations` - Conversaciones de chat
- `messages` - Mensajes

Ver `supabase/schema.sql` para el esquema completo.

## 🚀 Instalación

### Prerrequisitos

- Flutter 3.2.0 o superior
- Cuenta en Supabase
- Dart SDK

### Configuración

1. Clonar el repositorio:
```bash
git clone https://github.com/tu-usuario/artmarket-app.git
cd artmarket-app
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Configurar Supabase:
   - Crear proyecto en [Supabase](https://supabase.com)
   - Ejecutar el script SQL en `supabase/schema.sql`
   - Crear bucket `product-images` en Storage (público)
   - Crear bucket `avatars` en Storage (público)

4. Configurar variables de entorno:
```bash
cp .env.example .env
```

Editar `.env` con tus credenciales:
```
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
STORAGE_BUCKET=product-images
```

5. Ejecutar la app:
```bash
flutter run
```

## 📋 Validaciones

- **Precio**: Mayor a 0
- **Stock**: No negativo
- **Descripción**: Mínimo 50 caracteres
- **Imágenes**: Máximo 3 por producto, 1MB cada una
- **Productos destacados**: Máximo 3 por vendedor

## 🔒 Seguridad (RLS)

Las políticas de Row Level Security están configuradas para:
- Usuarios solo pueden editar sus propios productos
- Compradores no pueden crear productos
- Mensajes solo visibles para participantes de la conversación

## 📝 Commits Sugeridos

1. `init: project setup with very good cli`
2. `feat(auth): add dual role authentication`
3. `feat(products): implement product crud`
4. `feat(storage): integrate supabase storage for images`
5. `feat(search): add search with debounce and filters`
6. `feat(favorites): implement favorites system`
7. `feat(chat): add realtime chat functionality`
8. `feat(feed): implement infinite scroll`
9. `feat(ui): add pull to refresh`
10. `feat(images): implement image compression`
11. `feat(navigation): configure shell routes`
12. `feat(optimistic): add optimistic updates`
13. `fix(retry): implement retry policy for uploads`
14. `perf(cache): add image caching`
15. `docs: complete readme and documentation`

## 🎨 Diseño

- **Colores**: Paleta artesanal con tonos cobre, marrón y arena
- **Tipografía**: Playfair Display (títulos), Lora (cuerpo)
- **Iconografía**: Material Design Icons

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE)

## 👥 Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir cambios mayores.

---

Desarrollado con ❤️ usando Flutter y Supabase
