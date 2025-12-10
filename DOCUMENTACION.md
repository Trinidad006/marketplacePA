# 📚 Documentación Completa - ArtMarket

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
3. [Stack Tecnológico](#stack-tecnológico)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Configuración e Instalación](#configuración-e-instalación)
6. [Base de Datos](#base-de-datos)
7. [Funcionalidades Detalladas](#funcionalidades-detalladas)
8. [Flujos de Usuario](#flujos-de-usuario)
9. [Seguridad y RLS](#seguridad-y-rls)
10. [Guía de Desarrollo](#guía-de-desarrollo)
11. [Testing](#testing)
12. [Deployment](#deployment)
13. [Troubleshooting](#troubleshooting)

---

## 📖 Descripción General

**ArtMarket** es una aplicación móvil desarrollada en Flutter que funciona como marketplace para productos artesanales. Conecta artesanos (vendedores) con compradores interesados en productos únicos y hechos a mano.

### Objetivo Principal
Facilitar la comercialización de productos artesanales mediante una plataforma intuitiva que incluye:
- Publicación y gestión de productos
- Búsqueda y filtrado avanzado
- Sistema de favoritos
- Chat en tiempo real entre compradores y vendedores
- Perfiles de vendedor con estadísticas

### Características Principales
- ✅ Autenticación dual (Comprador/Vendedor)
- ✅ CRUD completo de productos
- ✅ Upload y compresión de imágenes
- ✅ Búsqueda con debounce y filtros
- ✅ Sistema de favoritos con optimistic updates
- ✅ Chat en tiempo real con Supabase Realtime
- ✅ Infinite scroll con paginación
- ✅ Pull to refresh
- ✅ Caché de imágenes
- ✅ Retry policy para uploads

---

## 🏗️ Arquitectura del Proyecto

### Patrón Arquitectónico
El proyecto sigue una **arquitectura por features** con separación clara de responsabilidades:

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Screens, Widgets, Router)            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Business Logic                 │
│  (Providers, State Management)          │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Data Layer                     │
│  (Services, Models, Supabase)           │
└─────────────────────────────────────────┘
```

### Principios de Diseño
1. **Separación de Concerns**: Cada feature es independiente
2. **Single Responsibility**: Cada clase tiene una responsabilidad única
3. **Dependency Injection**: Providers para gestión de estado
4. **Repository Pattern**: Servicios abstraen el acceso a datos
5. **Optimistic Updates**: Mejora la UX con actualizaciones inmediatas

### Gestión de Estado
- **Provider**: Para estado global y compartido
- **ChangeNotifier**: Para estado local de widgets
- **StateNotifier**: Para lógica de negocio compleja

---

## 🛠️ Stack Tecnológico

### Frontend
| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Flutter** | 3.x | Framework UI multiplataforma |
| **Dart** | 3.10.0+ | Lenguaje de programación |
| **Material Design** | Latest | Sistema de diseño |

### Estado y Navegación
| Paquete | Versión | Uso |
|---------|---------|-----|
| `provider` | ^6.1.5 | Gestión de estado global |
| `state_notifier` | ^1.0.0 | Estado inmutable |
| `flutter_state_notifier` | ^1.0.0 | Integración con Flutter |
| `go_router` | ^14.8.1 | Navegación declarativa con shell routes |

### Backend y Servicios
| Servicio | Uso |
|----------|-----|
| **Supabase** | Backend completo (Auth, Database, Storage, Realtime) |
| `supabase_flutter` | ^2.10.3 | SDK oficial de Supabase |
| `dio` | ^5.9.0 | Cliente HTTP |
| `dio_smart_retry` | ^7.0.1 | Retry automático para requests |

### Imágenes y Media
| Paquete | Versión | Uso |
|---------|---------|-----|
| `cached_network_image` | ^3.4.1 | Caché de imágenes de red |
| `image_picker` | ^1.2.1 | Selección de imágenes |
| `flutter_image_compress` | ^2.4.0 | Compresión de imágenes |

### UI y Animaciones
| Paquete | Versión | Uso |
|---------|---------|-----|
| `lottie` | ^3.3.2 | Animaciones JSON |
| `shimmer` | ^3.0.0 | Efecto de carga |
| `flutter_staggered_grid_view` | ^0.7.0 | Grid asimétrico |

### Utilidades
| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_dotenv` | ^5.2.1 | Variables de entorno |
| `uuid` | ^4.5.2 | Generación de UUIDs |
| `intl` | ^0.20.2 | Internacionalización |
| `timeago` | ^3.7.0 | Timestamps relativos |
| `equatable` | ^2.0.7 | Comparación de objetos |

### Desarrollo y Calidad
| Paquete | Versión | Uso |
|---------|---------|-----|
| `very_good_analysis` | ^7.0.0 | Análisis de código y linting |
| `flutter_lints` | ^6.0.0 | Reglas de lint adicionales |

---

## 📁 Estructura del Proyecto

```
artmarket_app/
├── lib/
│   ├── core/                          # Código compartido y base
│   │   ├── constants/
│   │   │   └── app_constants.dart     # Constantes globales
│   │   ├── models/                    # Modelos de datos
│   │   │   ├── conversation.dart      # Modelo de conversación
│   │   │   ├── favorite.dart          # Modelo de favorito
│   │   │   ├── message.dart           # Modelo de mensaje
│   │   │   ├── product.dart           # Modelo de producto
│   │   │   ├── user_profile.dart      # Modelo de perfil
│   │   │   └── models.dart            # Exportaciones
│   │   ├── providers/                 # Providers globales
│   │   │   ├── app_providers.dart     # Configuración de providers
│   │   │   ├── auth_provider.dart     # Autenticación
│   │   │   ├── chat_provider.dart     # Chat
│   │   │   ├── favorites_provider.dart # Favoritos
│   │   │   └── products_provider.dart  # Productos
│   │   ├── router/
│   │   │   └── app_router.dart        # Configuración de rutas
│   │   ├── services/                  # Servicios
│   │   │   ├── dio_service.dart       # Cliente HTTP
│   │   │   ├── storage_service.dart   # Gestión de imágenes
│   │   │   └── supabase_service.dart  # Servicio Supabase
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Tema de la app
│   │   ├── utils/
│   │   │   └── timeago_config.dart    # Configuración timeago
│   │   └── widgets/
│   │       └── main_scaffold.dart     # Scaffold principal
│   │
│   ├── features/                      # Features por dominio
│   │   ├── auth/                      # Autenticación
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   ├── role_selection_screen.dart
│   │   │   │   └── splash_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_text_field.dart
│   │   │
│   │   ├── products/                  # Productos
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart           # Feed principal
│   │   │   │   ├── product_detail_screen.dart # Detalle
│   │   │   │   ├── new_product_screen.dart    # Crear producto
│   │   │   │   ├── product_form_screen.dart   # Editar producto
│   │   │   │   └── my_products_screen.dart     # Mis productos
│   │   │   └── widgets/
│   │   │       ├── product_card.dart          # Tarjeta de producto
│   │   │       └── search_filter_bar.dart      # Búsqueda y filtros
│   │   │
│   │   ├── favorites/                 # Favoritos
│   │   │   └── screens/
│   │   │       └── favorites_screen.dart
│   │   │
│   │   ├── chat/                      # Chat
│   │   │   └── screens/
│   │   │       ├── chat_screen.dart
│   │   │       └── conversations_screen.dart
│   │   │
│   │   └── profile/                   # Perfil
│   │       └── screens/
│   │           ├── profile_screen.dart
│   │           ├── edit_profile_screen.dart
│   │           └── seller_profile_screen.dart
│   │
│   └── main.dart                      # Punto de entrada
│
├── supabase/                          # Scripts SQL
│   ├── schema.sql                     # Esquema de base de datos
│   ├── storage_policies.sql           # Políticas de Storage
│   ├── seed_products.sql              # Datos de prueba
│   └── update_products_images.sql     # Actualizar imágenes
│
├── assets/                            # Recursos
│   ├── animations/                    # Animaciones Lottie
│   └── images/                        # Imágenes estáticas
│
├── test/                              # Tests
│   └── widget_test.dart
│
├── android/                           # Configuración Android
├── ios/                               # Configuración iOS
├── web/                               # Configuración Web
├── windows/                           # Configuración Windows
├── linux/                             # Configuración Linux
└── macos/                             # Configuración macOS
```

---

## ⚙️ Configuración e Instalación

### Prerrequisitos

1. **Flutter SDK** 3.2.0 o superior
   ```bash
   flutter --version
   ```

2. **Dart SDK** 3.10.0 o superior (incluido con Flutter)

3. **Cuenta de Supabase**
   - Crear proyecto en [supabase.com](https://supabase.com)
   - Obtener URL y anon key

4. **Git** (para clonar el repositorio)

### Instalación Paso a Paso

#### 1. Clonar el Repositorio
```bash
git clone https://github.com/Trinidad006/marketplacePA.git
cd marketplacePA/artmarket_app
```

#### 2. Instalar Dependencias
```bash
flutter pub get
```

#### 3. Configurar Supabase

**a) Crear Proyecto en Supabase:**
1. Ir a [supabase.com](https://supabase.com)
2. Crear nuevo proyecto
3. Anotar la URL del proyecto y la anon key

**b) Ejecutar Scripts SQL:**
1. Ir a SQL Editor en Supabase Dashboard
2. Ejecutar `supabase/schema.sql` (crea tablas y políticas RLS)
3. Ejecutar `supabase/storage_policies.sql` (configura Storage)

**c) Configurar Storage:**
1. Ir a Storage → Buckets
2. Crear bucket `product-images` (público)
3. Crear bucket `avatars` (público)
4. Verificar que las políticas RLS estén aplicadas

**d) Habilitar Realtime:**
1. Ir a Database → Replication
2. Habilitar para tablas: `messages`, `conversations`

#### 4. Configurar Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:
```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

**⚠️ Importante:** El archivo `.env` está en `.gitignore` y no se sube al repositorio.

#### 5. Ejecutar la Aplicación

**Android:**
```bash
flutter run -d <device-id>
```

**iOS:**
```bash
flutter run -d <device-id>
```

**Ver dispositivos disponibles:**
```bash
flutter devices
```

---

## 🗄️ Base de Datos

### Esquema de Tablas

#### 1. `user_profiles`
Perfiles de usuario con roles (buyer/seller).

```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    role TEXT NOT NULL CHECK (role IN ('buyer', 'seller')),
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Campos:**
- `id`: UUID del usuario (FK a auth.users)
- `role`: 'buyer' o 'seller'
- `full_name`: Nombre completo
- `avatar_url`: URL del avatar
- `bio`: Biografía del usuario

#### 2. `products`
Productos publicados por vendedores.

```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    seller_id UUID NOT NULL REFERENCES user_profiles(id),
    name TEXT NOT NULL,
    description TEXT NOT NULL CHECK (char_length(description) >= 50),
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    category TEXT NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    images TEXT[] NOT NULL DEFAULT '{}',
    is_featured BOOLEAN NOT NULL DEFAULT false,
    views_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Campos:**
- `id`: UUID único del producto
- `seller_id`: FK al vendedor
- `name`: Nombre del producto
- `description`: Descripción (mín. 50 caracteres)
- `price`: Precio (debe ser > 0)
- `category`: Categoría del producto
- `stock`: Cantidad disponible (>= 0)
- `images`: Array de URLs de imágenes
- `is_featured`: Si es destacado (máx 3 por vendedor)
- `views_count`: Contador de vistas

#### 3. `favorites`
Relación N:M entre usuarios y productos favoritos.

```sql
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id),
    product_id UUID NOT NULL REFERENCES products(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);
```

#### 4. `conversations`
Conversaciones de chat entre usuarios.

```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    buyer_id UUID NOT NULL REFERENCES user_profiles(id),
    seller_id UUID NOT NULL REFERENCES user_profiles(id),
    product_id UUID REFERENCES products(id),
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 5. `messages`
Mensajes dentro de conversaciones.

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    sender_id UUID NOT NULL REFERENCES user_profiles(id),
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Índices

Para optimizar consultas, se crean índices en:
- `user_profiles.role`
- `products.seller_id`
- `products.category`
- `products.created_at` (DESC)
- `products.price`
- `products.views_count` (DESC)
- `favorites.user_id`
- `favorites.product_id`
- `conversations.buyer_id`
- `conversations.seller_id`
- `messages.conversation_id`

### Triggers

**Auto-crear perfil al registrar usuario:**
```sql
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();
```

**Actualizar `updated_at` automáticamente:**
```sql
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

---

## 🎯 Funcionalidades Detalladas

### 1. Autenticación Dual

#### Registro
- Selección de rol (Comprador/Vendedor)
- Validación de email
- Verificación por email obligatoria
- Creación automática de perfil

#### Login
- Autenticación con email/password
- Manejo de sesión persistente
- Redirección según rol

#### Estados de Autenticación
- `initial`: Estado inicial
- `loading`: Cargando
- `authenticated`: Autenticado
- `unauthenticated`: No autenticado

### 2. Gestión de Productos

#### Crear Producto (Vendedores)
- Formulario con validación
- Upload de hasta 3 imágenes
- Compresión automática (máx 1MB)
- Selección de categoría
- Precio y stock
- Descripción (mín. 50 caracteres)

#### Editar Producto
- Solo el vendedor propietario
- Actualización de todos los campos
- Reemplazo de imágenes

#### Eliminar Producto
- Confirmación antes de eliminar
- Eliminación de imágenes de Storage
- Actualización de favoritos

#### Listar Productos
- Feed principal con paginación (20 items)
- Infinite scroll
- Pull to refresh
- Filtros y ordenamiento

### 3. Búsqueda y Filtros

#### Búsqueda
- Búsqueda por nombre
- Debounce de 300ms
- Búsqueda en tiempo real

#### Filtros
- **Categoría**: Filtrar por categoría específica
- **Precio**: Rango mínimo y máximo
- **Disponibilidad**: Solo productos con stock > 0

#### Ordenamiento
- Más recientes (por defecto)
- Menor precio
- Mayor precio
- Más populares (por vistas)

### 4. Sistema de Favoritos

#### Agregar/Quitar Favoritos
- Botón de corazón con animación
- Optimistic update (actualización inmediata)
- Sincronización con backend
- Manejo de errores con rollback

#### Lista de Favoritos
- Pantalla dedicada
- Grid de productos favoritos
- Acceso rápido al detalle

### 5. Chat en Tiempo Real

#### Iniciar Conversación
- Desde detalle de producto
- Botón "Contactar vendedor"
- Creación automática de conversación

#### Lista de Conversaciones
- Todas las conversaciones del usuario
- Último mensaje visible
- Indicador de no leídos
- Timestamp relativo

#### Chat Individual
- Mensajes en tiempo real
- Scroll automático a último mensaje
- Indicador de lectura
- Envío de mensajes

#### Realtime
- Suscripción a cambios en `messages`
- Actualización automática sin refresh
- Notificaciones en tiempo real

### 6. Perfiles

#### Perfil de Usuario
- Información personal
- Avatar
- Biografía
- Edición de perfil

#### Perfil de Vendedor (Público)
- Información del vendedor
- Lista de productos publicados
- Estadísticas (tiempo en plataforma)
- Botón para contactar

---

## 🔄 Flujos de Usuario

### Flujo: Registro y Primer Uso

```
1. Usuario abre app → Splash Screen
2. Verifica autenticación
3. Si no autenticado → Login/Register
4. Selecciona rol (Comprador/Vendedor)
5. Completa registro
6. Verifica email
7. Login automático
8. Redirección según rol:
   - Comprador → Home (feed de productos)
   - Vendedor → Home + botón "Publicar"
```

### Flujo: Publicar Producto (Vendedor)

```
1. Vendedor presiona "Publicar"
2. Abre formulario de producto
3. Completa campos:
   - Nombre, descripción, precio, categoría, stock
4. Selecciona imágenes (máx 3)
5. Imágenes se comprimen automáticamente
6. Presiona "Guardar"
7. Upload de imágenes a Supabase Storage
8. Creación de producto en BD
9. Redirección a "Mis Productos"
10. Producto visible en feed
```

### Flujo: Buscar y Filtrar (Comprador)

```
1. Comprador en Home
2. Escribe en barra de búsqueda
3. Debounce de 300ms
4. Aplica filtros (categoría, precio, disponibilidad)
5. Selecciona ordenamiento
6. Resultados actualizados en tiempo real
7. Scroll infinito carga más productos
8. Pull to refresh recarga
```

### Flujo: Agregar a Favoritos

```
1. Comprador ve producto
2. Presiona corazón
3. Optimistic update (corazón se llena inmediatamente)
4. Request al backend
5. Si éxito → Confirmación silenciosa
6. Si error → Rollback (corazón se vacía) + mensaje
```

### Flujo: Chat con Vendedor

```
1. Comprador ve producto
2. Presiona "Contactar vendedor"
3. Se crea conversación (si no existe)
4. Abre pantalla de chat
5. Escribe mensaje
6. Mensaje se envía
7. Vendedor recibe en tiempo real
8. Vendedor responde
9. Comprador recibe en tiempo real
```

---

## 🔒 Seguridad y RLS

### Row Level Security (RLS)

Todas las tablas tienen RLS habilitado para seguridad a nivel de fila.

#### Políticas de `user_profiles`
- **SELECT**: Todos pueden leer perfiles (públicos)
- **UPDATE**: Solo el usuario puede actualizar su propio perfil

#### Políticas de `products`
- **SELECT**: Todos pueden leer productos (públicos)
- **INSERT**: Solo vendedores pueden crear productos
- **UPDATE**: Solo el vendedor propietario puede actualizar
- **DELETE**: Solo el vendedor propietario puede eliminar

#### Políticas de `favorites`
- **SELECT**: Usuario solo ve sus propios favoritos
- **INSERT**: Usuario solo puede agregar sus propios favoritos
- **DELETE**: Usuario solo puede eliminar sus propios favoritos

#### Políticas de `conversations`
- **SELECT**: Usuario solo ve conversaciones donde participa
- **INSERT**: Usuario puede crear conversaciones donde es buyer o seller

#### Políticas de `messages`
- **SELECT**: Usuario solo ve mensajes de sus conversaciones
- **INSERT**: Usuario solo puede enviar mensajes en sus conversaciones

### Storage Policies

#### Bucket `product-images`
- **INSERT**: Usuarios autenticados pueden subir en su carpeta (`user_id/`)
- **SELECT**: Lectura pública de todas las imágenes
- **DELETE/UPDATE**: Solo el dueño puede modificar sus imágenes

#### Bucket `avatars`
- **INSERT**: Usuarios autenticados pueden subir su propio avatar
- **SELECT**: Lectura pública
- **DELETE/UPDATE**: Solo el dueño puede modificar su avatar

---

## 💻 Guía de Desarrollo

### Estructura de un Feature

Cada feature sigue esta estructura:

```
feature_name/
├── models/          # Modelos específicos del feature
├── providers/       # Lógica de negocio y estado
├── screens/         # Pantallas
└── widgets/         # Widgets reutilizables del feature
```

### Crear un Nuevo Feature

1. **Crear estructura de carpetas:**
```bash
mkdir -p lib/features/nuevo_feature/{models,providers,screens,widgets}
```

2. **Crear modelo (si aplica):**
```dart
// lib/features/nuevo_feature/models/nuevo_model.dart
class NuevoModel {
  // ...
}
```

3. **Crear provider:**
```dart
// lib/features/nuevo_feature/providers/nuevo_provider.dart
class NuevoProvider extends ChangeNotifier {
  // ...
}
```

4. **Registrar provider:**
```dart
// lib/core/providers/app_providers.dart
ChangeNotifierProvider(create: (_) => NuevoProvider()),
```

5. **Crear pantalla:**
```dart
// lib/features/nuevo_feature/screens/nuevo_screen.dart
class NuevoScreen extends StatelessWidget {
  // ...
}
```

6. **Agregar ruta:**
```dart
// lib/core/router/app_router.dart
GoRoute(
  path: '/nuevo',
  builder: (context, state) => const NuevoScreen(),
),
```

### Convenciones de Código

#### Nombres de Archivos
- `snake_case` para archivos: `product_card.dart`
- `PascalCase` para clases: `ProductCard`

#### Nombres de Variables
- `camelCase` para variables: `productName`
- `_private` para privadas: `_internalState`

#### Comentarios
- Documentación con `///` para clases públicas
- Comentarios `//` para explicaciones internas

#### Imports
- Orden: Flutter → Packages → Relativos
- Agrupar por tipo

### Manejo de Errores

```dart
try {
  // Operación
} catch (e, stackTrace) {
  debugPrint('❌ Error: $e');
  debugPrint('📚 Stack trace: $stackTrace');
  // Mostrar mensaje al usuario
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

### Logging

Usar `debugPrint` con emojis para facilitar debugging:
```dart
debugPrint('✅ Operación exitosa');
debugPrint('⚠️ Advertencia');
debugPrint('❌ Error');
debugPrint('📝 Información');
```

---

## 🧪 Testing

### Estructura de Tests

```
test/
├── unit/              # Tests unitarios
├── widget/            # Tests de widgets
└── integration/       # Tests de integración
```

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Test específico
flutter test test/unit/products_provider_test.dart

# Con cobertura
flutter test --coverage
```

### Ejemplo de Test

```dart
// test/unit/products_provider_test.dart
void main() {
  group('ProductsProvider', () {
    test('debe cargar productos correctamente', () async {
      // Arrange
      final provider = ProductsProvider();
      
      // Act
      await provider.loadProducts();
      
      // Assert
      expect(provider.products, isNotEmpty);
    });
  });
}
```

---

## 🚀 Deployment

### Android

1. **Generar keystore:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

2. **Configurar `android/key.properties`:**
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

3. **Build APK:**
```bash
flutter build apk --release
```

4. **Build App Bundle:**
```bash
flutter build appbundle --release
```

### iOS

1. **Configurar en Xcode:**
   - Abrir `ios/Runner.xcworkspace`
   - Configurar signing y capabilities

2. **Build:**
```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

---

## 🔧 Troubleshooting

### Error: "StorageException: new row violates row-level security policy"

**Causa:** Políticas RLS de Storage no configuradas.

**Solución:**
1. Ejecutar `supabase/storage_policies.sql` en Supabase SQL Editor
2. Verificar que los buckets sean públicos
3. Verificar que las políticas estén activas

### Error: "No pubspec.yaml file found"

**Causa:** No estás en el directorio correcto.

**Solución:**
```bash
cd artmarket_app
flutter pub get
```

### Error: "GoRouter exception"

**Causa:** Conflicto en configuración de rutas.

**Solución:**
- Verificar que rutas específicas estén antes de rutas con parámetros
- Verificar que no haya múltiples `errorBuilder`, `errorPageBuilder` o `onException`

### Imágenes no se cargan

**Causa:** URLs incorrectas o Storage no configurado.

**Solución:**
1. Verificar que las URLs sean públicas
2. Verificar políticas de Storage
3. Verificar que el bucket sea público

### Chat no funciona en tiempo real

**Causa:** Realtime no habilitado.

**Solución:**
1. Ir a Database → Replication en Supabase
2. Habilitar para tablas `messages` y `conversations`

---

## 📊 Métricas y Constantes

### Constantes de la App

```dart
// Paginación
pageSize: 20 productos por página
maxFeaturedProducts: 3 productos destacados por vendedor
maxProductImages: 3 imágenes por producto

// Búsqueda
searchDebounceMs: 300ms de delay

// Validación
minDescriptionLength: 50 caracteres
minPrice: 0.01

// Imágenes
maxImageSizeBytes: 1MB (1024 * 1024)
imageQuality: 70%

// Retry
maxRetryAttempts: 3 intentos
```

### Categorías de Productos

- Cerámica
- Textiles
- Joyería
- Madera
- Vidrio
- Cuero
- Metal
- Papel
- Pintura
- Escultura
- Otros

---

## 📝 Commits del Proyecto

El proyecto tiene 17 commits organizados:

1. `init: project setup with very good cli`
2. `feat(images): implement image compression`
3. `feat(optimistic): add optimistic updates`
4. `fix(retry): implement retry policy for uploads`
5. `perf(cache): add image caching`
6. `feat(core): add core services and models`
7. `chore: add platform configurations and assets`
8. `feat(auth): add dual role authentication`
9. `feat(products): implement product crud`
10. `feat(storage): integrate supabase storage for images`
11. `feat(search): add search with debounce and filter`
12. `feat(favorites): implement favorites system`
13. `feat(chat): add realtime chat functionality`
14. `feat(feed): implement infinite scroll`
15. `feat(ui): add pull to refresh`
16. `feat(navigation): configure shell routes`
17. `docs: complete readme and documentation`

---

## 🎨 Diseño y Tema

### Paleta de Colores

- **Primario**: Tonos cobre y marrón artesanal
- **Secundario**: Arena y beige
- **Acento**: Colores cálidos

### Tipografía

- **Títulos**: Playfair Display
- **Cuerpo**: Lora
- **UI**: Roboto (Material Design)

### Componentes

- Material Design 3
- Componentes personalizados
- Animaciones suaves
- Transiciones fluidas

---

## 📞 Soporte y Contacto

Para problemas o preguntas:
- Abrir issue en GitHub
- Revisar documentación de Supabase
- Consultar documentación de Flutter

---

**Última actualización:** Diciembre 2025
**Versión:** 1.0.0
**Desarrollado con:** Flutter, Supabase, y ❤️

