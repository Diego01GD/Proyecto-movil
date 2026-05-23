# DOCUMENTACIÓN DEL PROYECTO - SKILLSWAP

## 1. INFORMACIÓN GENERAL DEL PROYECTO

### Nombre del Proyecto

**SkillSwap**

### Descripción Ejecutiva

SkillSwap es una aplicación móvil desarrollada en Flutter que facilita el intercambio de habilidades y conocimientos entre estudiantes universitarios. La plataforma conecta a usuarios con perfiles complementarios, permitiendo que aquellos que dominan una habilidad puedan enseñarla a quienes deseen aprenderla, creando una comunidad de aprendizaje colaborativo.

### Versión

**1.0.0**

---

## 2. PROBLEMÁTICA A RESOLVER

### Contexto

En el entorno universitario actual, los estudiantes enfrentan varios desafíos:

1. **Acceso limitado a tutorías especializadas**: Las tutorías académicas oficiales suelen ser caras o limitadas en disponibilidad.

2. **Brecha de conocimiento entre estudiantes**: Existen estudiantes avanzados en ciertos campos que podrían ayudar a otros, pero no hay mecanismo que los conecte.

3. **Falta de visibilidad de habilidades disponibles**: No existe una plataforma donde se cataloguen y publiciten las habilidades que los estudiantes pueden enseñar.

4. **Desaprovechamiento de recursos humanos**: El conocimiento y experiencia de estudiantes avanzados no se aprovecha de manera estructurada.

5. **Dificultad para encontrar estudios de grupo**: No hay forma fácil de identificar estudiantes disponibles en horarios específicos para colaborar.

### Necesidad

Se requiere una solución tecnológica que:

- Permita a estudiantes registrar y buscar habilidades específicas
- Facilite el emparejamiento entre quién enseña y quién aprende
- Proporcione visibilidad de disponibilidad horaria
- Ofrezca un método de contacto directo y seguro
- Funcione en dispositivos móviles (lugar donde pasan más tiempo los estudiantes)

---

## 3. OBJETIVOS DEL PROYECTO

### Objetivo General

Desarrollar una plataforma móvil que facilite el intercambio colaborativo de habilidades entre estudiantes universitarios, promoviendo el aprendizaje peer-to-peer y la construcción de una comunidad de apoyo académico.

### Objetivos Específicos

1. **Gestión de Perfiles**
   - Permitir registro seguro de usuarios con autenticación
   - Almacenar información académica (carrera, semestre, GPA)
   - Habilitar la edición y actualización de perfiles

2. **Catálogo de Habilidades**
   - Crear un sistema de categorización de habilidades
   - Permitir que usuarios registren habilidades que pueden enseñar
   - Permitir que usuarios registren intereses en habilidades a aprender
   - Clasificar habilidades por nivel de dominio (básico, intermedio, avanzado)

3. **Búsqueda y Filtrado**
   - Implementar búsqueda por nombre de usuario
   - Filtrar usuarios por categoría de habilidad
   - Filtrar por nivel de dominio requerido
   - Filtrar por disponibilidad de horario

4. **Gestión de Disponibilidad**
   - Permitir que usuarios registren su disponibilidad horaria
   - Diferenciar entre turnos (mañana, tarde, noche)
   - Mostrar disponibilidad por día de la semana
   - Permitir comentarios sobre disponibilidad

5. **Comunicación**
   - Facilitar contacto directo entre usuarios interesados
   - Implementar envío de correos para coordinar sesiones
   - Mantener registro de contactos efectivos

6. **Plataforma Multiplataforma**
   - Desarrollar aplicación funcional en iOS
   - Desarrollar aplicación funcional en Android
   - Asegurar experiencia responsive en diferentes tamaños de pantalla

---

## 4. INFORMACIÓN TÉCNICA

### 4.1 Arquitectura General

```
┌─────────────────────────────────────────┐
│         APLICACIÓN MÓVIL (Flutter)      │
│                                         │
├─────────────────────────────────────────┤
│  • Landing Page                         │
│  • Autenticación (Login/SignUp)         │
│  • Dashboard & Búsqueda                 │
│  • Gestión de Perfil                    │
│  • Comunicación con Usuarios            │
└─────────────────────────────────────────┘
            ↓ HTTP/REST
┌─────────────────────────────────────────┐
│       BACKEND - Supabase (BaaS)         │
│                                         │
├─────────────────────────────────────────┤
│  • Autenticación (Auth)                 │
│  • Base de Datos PostgreSQL             │
│  • Almacenamiento de Archivos           │
│  • API REST Automática                  │
└─────────────────────────────────────────┘
```

### 4.2 Stack Tecnológico

#### Framework Principal

- **Flutter 3.10.8+**: Framework multiplataforma para desarrollo de aplicaciones móviles nativas
  - Lenguaje: Dart
  - Compilación: Ahead-of-Time (AOT) para iOS y Android

#### Backend (BaaS)

- **Supabase 2.0.0**: Plataforma Backend as a Service basada en código abierto
  - PostgreSQL como base de datos relacional
  - Autenticación integrada (JWT)
  - API REST auto-generada
  - Real-time capabilities

#### Dependencias del Proyecto

| Librería           | Versión | Propósito                               |
| ------------------ | ------- | --------------------------------------- |
| `cupertino_icons`  | ^1.0.8  | Iconografía iOS/Material Design         |
| `supabase_flutter` | 2.0.0   | Cliente Supabase para Flutter           |
| `image_picker`     | ^1.2.2  | Selección de imágenes de galería/cámara |
| `url_launcher`     | ^6.2.0  | Apertura de URLs y envío de correos     |
| `app_links`        | ^3.5.1  | Manejo de deep links                    |
| `flutter_lints`    | ^6.0.0  | Análisis estático de código (dev)       |

### 4.3 Estructura de Base de Datos

#### Tablas Principales

**1. profiles**

```sql
- id: UUID (PK, FK a auth.users)
- full_name: VARCHAR
- career: VARCHAR
- gpa: DECIMAL
- is_complete: BOOLEAN
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

**2. skills**

```sql
- id: UUID (PK)
- name: VARCHAR (Único)
- category: VARCHAR
- created_at: TIMESTAMP
```

**3. user_skills**

```sql
- profile_id: UUID (FK)
- skill_id: UUID (FK)
- level: ENUM ('basic', 'intermediate', 'advanced')
- created_at: TIMESTAMP
```

**4. user_interests**

```sql
- profile_id: UUID (FK)
- skill_id: UUID (FK)
- created_at: TIMESTAMP
```

**5. time_slots**

```sql
- id: UUID (PK)
- range: VARCHAR
- shift: VARCHAR ('morning', 'afternoon', 'evening')
```

**6. user_availability**

```sql
- profile_id: UUID (FK)
- day: VARCHAR
- slot_id: UUID (FK)
- comment: TEXT
```

### 4.4 Estructura de Directorios

```
proyecto_movil/
├── lib/                              # Código Dart principal
│   ├── main.dart                     # Punto de entrada + configuración Supabase
│   ├── landing_page.dart             # Página de inicio (bienvenida)
│   ├── login_page.dart               # Formulario de login
│   ├── signup_page.dart              # Formulario de registro
│   ├── reset_password_page.dart      # Reset de contraseña
│   ├── personalize_experience_page.dart  # Selección de habilidades inicial
│   ├── dashboard_page.dart           # Búsqueda y filtrado de usuarios
│   ├── edit_profile_page.dart        # Edición de perfil
│   └── forgot_password_page.dart     # Recuperación de contraseña
│
├── android/                          # Código Android nativo
│   ├── app/src/
│   ├── build.gradle.kts
│   └── gradle.properties
│
├── ios/                              # Código iOS nativo
│   ├── Runner/
│   ├── Runner.xcodeproj
│   └── Runner.xcworkspace
│
├── web/                              # Assets web (iconos, manifest)
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│
├── windows/                          # Soporte Windows
├── macos/                            # Soporte macOS
├── linux/                            # Soporte Linux
│
├── test/                             # Tests unitarios y de widgets
│   └── widget_test.dart
│
├── build/                            # Artefactos compilados (generado)
├── pubspec.yaml                      # Configuración de dependencias
├── analysis_options.yaml             # Reglas de linting
└── README.md                         # Documentación básica
```

### 4.5 Flujo de Autenticación

```
┌──────────────────────────────────────────────┐
│  Usuario (No autenticado)                    │
└─────────────────┬──────────────────────────┘
                  ↓
        ┌─────────────────────┐
        │   Landing Page      │
        │  (Intro & CTA)      │
        └─────────────────────┘
                  ↓
        ┌─────────────────────┐
        │   SignUp/Login      │
        │   (Supabase Auth)   │
        └─────────────────────┘
                  ↓
      ┌──────────────────────────────┐
      │ Personalize Experience Page  │
      │ (Seleccionar habilidades)    │
      └──────────────────────────────┘
                  ↓
        ┌─────────────────────┐
        │   Dashboard         │
        │  (Main App)         │
        └─────────────────────┘
                  ↓
      ┌──────────────────────────────┐
      │   Edit Profile/Search Users  │
      │   (Funcionalidades Secundarias)
      └──────────────────────────────┘
```

### 4.6 Flujo de Búsqueda y Conexión

```
1. Usuario abre Dashboard
   ↓
2. Carga lista de usuarios con habilidades
   ↓
3. Usuario aplica filtros:
   - Búsqueda por nombre
   - Categoría de habilidad
   - Nivel de dominio
   - Disponibilidad horaria
   ↓
4. Visualiza resultados filtrados
   ↓
5. Selecciona un usuario de interés
   ↓
6. Envía email a través de url_launcher
   ↓
7. Inician coordinación externa
```

### 4.7 Protecciones de Seguridad

- **Autenticación**: JWT tokens con Supabase
- **Validación de Contraseña**:
  - Mínimo 8 caracteres
  - Al menos una mayúscula
  - Al menos un número
  - Al menos un carácter especial
- **Base de Datos**: Supabase maneja encriptación en reposo
- **Conexiones**: HTTPS para todas las comunicaciones
- **Perfiles Públicos**: Solo información de perfil sin datos sensibles

### 4.8 Plataformas Soportadas

| Plataforma | Estado       | Requisitos           |
| ---------- | ------------ | -------------------- |
| Android    | ✅ Soportada | Android 7.0+         |
| iOS        | ✅ Soportada | iOS 11.0+            |
| Web        | ⚠️ Parcial   | Navegadores modernos |
| macOS      | ✅ Soportada | macOS 10.11+         |
| Windows    | ✅ Soportada | Windows 10+          |
| Linux      | ✅ Soportada | Ubuntu 16.04+        |

---

## 5. CARACTERÍSTICAS IMPLEMENTADAS

### 5.1 Pantallas Principales

#### Landing Page

- Introducción a SkillSwap
- Visualización del valor de la plataforma
- Botones de navegación (Login/SignUp)
- Responsiva para móvil y web

#### Autenticación (Login/SignUp)

- Registro de nuevos usuarios con validación de email
- Validación robusta de contraseña
- Formulario de login
- Recuperación de contraseña (forgot_password, reset_password)

#### Personalización de Experiencia

- Selección inicial de habilidades que puede enseñar
- Selección de habilidades que desea aprender
- Configuración de semestre académico

#### Dashboard

- Listado de usuarios con sus habilidades
- Filtrado por búsqueda de nombre
- Filtrado por categoría de habilidad
- Filtrado por nivel de dominio
- Filtrado por disponibilidad horaria
- Integración con email para contacto directo

#### Edición de Perfil

- Actualización de información personal
- Modificación de habilidades
- Cambio de disponibilidad horaria
- Selección de intereses de aprendizaje

### 5.2 Funcionalidades Clave

1. **Sistema de Habilidades Categorizado**
   - Programación
   - Idiomas
   - Diseño
   - Música
   - Matemáticas
   - Comunicación
   - Deportes
   - Herramientas digitales

2. **Niveles de Dominio**
   - Básico
   - Intermedio
   - Avanzado

3. **Gestión de Disponibilidad**
   - Por día de la semana
   - Turnos: Mañana, Tarde, Noche
   - Comentarios personalizados

4. **Sistema de Contacto**
   - Envío directo de emails
   - Inclusión de nombre del contactante
   - Coordinación directa entre usuarios

---

## 6. DATOS TÉCNICOS ADICIONALES

### 6.1 Versión del SDK y Dependencias

- **Dart SDK**: 3.10.8 o superior
- **Flutter SDK**: Última versión estable recomendada
- **Versión mínima de Android**: API 21 (5.0 Lollipop)
- **Versión mínima de iOS**: 11.0

### 6.2 Configuración de Build

- **Versión de la Aplicación**: 1.0.0+1
- **Configuración Multipataforma**: Se generan artefactos nativos para cada plataforma
- **Soporte a Material Design**: Habilitado

### 6.3 Integración con Backend

**Endpoints Supabase Utilizados**:

- `profiles` - Gestión de perfiles de usuario
- `skills` - Catálogo de habilidades disponibles
- `user_skills` - Habilidades que cada usuario puede enseñar
- `user_interests` - Intereses de aprendizaje de cada usuario
- `time_slots` - Slots de tiempo disponibles
- `user_availability` - Disponibilidad horaria por usuario
- `auth` - Autenticación y gestión de usuarios

---

## 7. FLUJO DE DESARROLLO

### Configuración Inicial

```bash
# Instalación de dependencias
flutter pub get

# Ejecución en desarrollo
flutter run

# Build de producción
flutter build apk    # Android
flutter build ipa    # iOS
```

### Análisis de Código

```bash
# Análisis estático
flutter analyze

# Formato de código
dart format lib/
```

### Testing

```bash
# Ejecutar tests
flutter test
```

---

## 8. PRÓXIMAS MEJORAS POTENCIALES

1. **Sistema de Calificaciones**: Implementar valoración entre usuarios después de sesiones
2. **Notificaciones Push**: Alertas cuando hay usuarios con habilidades complementarias
3. **Chat Integrado**: Mensajería dentro de la app en lugar de solo email
4. **Historial de Conexiones**: Registro de encuentros exitosos
5. **Sistema de Reputación**: Badges y reconocimiento de usuarios activos
6. **Calendario Compartido**: Visualización de disponibilidad en calendario
7. **Traducción Multiidioma**: Soporte para múltiples idiomas
8. **Modo Oscuro**: Tema oscuro para la interfaz
9. **Sincronización Offline**: Funcionamiento parcial sin conexión
10. **Integración con Calendario Google/Outlook**: Sincronización automática de disponibilidad

---

## 9. EQUIPO Y RECURSOS

### Tecnologías Utilizadas

- **Lenguajes**: Dart, Kotlin (Android), Swift (iOS)
- **Herramientas de Desarrollo**: Flutter SDK, Android Studio, Xcode
- **Plataforma de Backend**: Supabase (infraestructura en nube)
- **Control de Versiones**: Git

### Requisitos de Hardware (Desarrollo)

- RAM: 8GB mínimo
- Almacenamiento: 10GB para emuladores/SDKs
- Procesador: Dual-core de 2.5 GHz mínimo

---

## 10. CONCLUSIÓN

SkillSwap es una aplicación de propósito claro que aborda una necesidad real en la comunidad académica: conectar estudiantes con el conocimiento que necesitan con quienes ya lo poseen. Mediante una arquitectura moderna, Backend as a Service confiable y desarrollo multiplataforma con Flutter, la aplicación ofrece escalabilidad y mantenibilidad a largo plazo.

La plataforma está posicionada para crecer y evolucionar con funcionalidades adicionales que enriquezcan la experiencia del usuario y fortalezcan la comunidad de aprendizaje colaborativo.

---

**Fecha de Documentación**: 21 de mayo de 2026
**Versión del Documento**: 1.0
