# ALMA — Plan de Arquitectura & Lógica de Producto
## Firebase + Flutter (Arquitectura simplificada)

> Documento de referencia técnica y funcional para el desarrollo de ALMA, app móvil para parejas con Firebase como backend completamente serverless.
>
> **Estado:** En Desarrollo — v2.0
> **Última actualización:** 2026-06-01

---

## Tabla de Contenidos

1. [Visión General](#1-visión-general)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Estructura del Proyecto Flutter](#4-estructura-del-proyecto-flutter)
5. [Firestore — Estructura de Datos](#5-firestore--estructura-de-datos)
6. [Módulos y Lógica de Vistas](#6-módulos-y-lógica-de-vistas)
   - 6.1 [Autenticación & Emparejamiento](#61-autenticación--emparejamiento)
   - 6.2 [Cronograma](#62-cronograma)
   - 6.3 [Memes](#63-memes)
   - 6.4 [Recordatorios](#64-recordatorios)
   - 6.5 [Distancia](#65-distancia)
   - 6.6 [Diario](#66-diario)
   - 6.7 [Minijuegos](#67-minijuegos)
   - 6.8 [Pensamientos](#68-pensamientos)
7. [Realtime Listeners & Sincronización](#7-realtime-listeners--sincronización)
8. [Notificaciones Push (FCM)](#8-notificaciones-push-fcm)
9. [Reglas de Seguridad (Firestore)](#9-reglas-de-seguridad-firestore)
10. [Plan de Desarrollo por Fases](#10-plan-de-desarrollo-por-fases)
11. [Dependencias Flutter](#11-dependencias-flutter)
12. [Consideraciones Finales](#12-consideraciones-finales)

---

## 1. Visión General

**ALMA** es una aplicación móvil multiplataforma (Android / iOS / Web) diseñada para parejas. Cada usuario crea una cuenta y genera un **código de emparejamiento** que vincula dos cuentas. A partir de ahí, ambos comparten un espacio privado con siete módulos principales.

**Diferencia con el plan anterior:**
- Sin servidor backend propio (NestJS, PostgreSQL, Redis, Docker, Vultr).
- Firebase Firestore como base de datos en tiempo real.
- Firebase Functions (opcional) para lógica serverless si es necesaria.
- Costo: **$0 USD** para el MVP (plan Spark de Firebase, completamente gratis).

---

## 2. Stack Tecnológico

| Tecnología | Rol | Costo |
|---|---|---|
| Flutter 3.x | Framework UI multiplataforma | Gratis |
| Dart | Lenguaje | Gratis |
| Firebase Auth | Autenticación | Gratis (Plan Spark) |
| Firestore | Base de datos realtime | Gratis (1 GB, 50k lecturas/día) |
| Firebase Storage | Almacenamiento de imágenes | Gratis (5 GB) |
| Firebase Messaging (FCM) | Push notifications | Gratis |
| Riverpod 3 | Gestión de estado + StreamProvider | Gratis |
| go_router | Navegación declarativa | Gratis |
| geolocator | Ubicación (distancia) | Gratis |
| **Total inicial** | | **$0 USD** |

---

## 3. Arquitectura del Sistema

```
┌─────────────────────────────────┐
│      Flutter App (Cliente)       │
│  ┌──────────┐  ┌─────────────┐  │
│  │ Firestore│  │ Firebase    │  │
│  │Listeners │  │ Auth + FCM  │  │
│  └────┬─────┘  └──────┬──────┘  │
└──────┼─────────────────┼─────────┘
       │                 │
       ▼                 ▼
   ┌───────────────────────────┐
   │   Firebase (Google Cloud) │
   │                           │
   │  ┌─────────────────────┐  │
   │  │  Firestore DB       │  │
   │  │  (Realtime)         │  │
   │  └─────────────────────┘  │
   │                           │
   │  ┌─────────────────────┐  │
   │  │  Authentication     │  │
   │  │  (Email/Password)   │  │
   │  └─────────────────────┘  │
   │                           │
   │  ┌─────────────────────┐  │
   │  │  Storage            │  │
   │  │  (imágenes/memes)   │  │
   │  └─────────────────────┘  │
   │                           │
   │  ┌─────────────────────┐  │
   │  │  FCM (Push Notif)   │  │
   │  └─────────────────────┘  │
   │                           │
   │  ┌─────────────────────┐  │
   │  │  Functions (opt)    │  │
   │  │  (scheduled tasks)  │  │
   │  └─────────────────────┘  │
   └───────────────────────────┘
```

### Estructura Firestore

```
/users/{uid}
  name, email, pairCode, coupleId, avatarUrl, fcmToken, birthday

/pairCodes/{code}
  userId

/couples/{coupleId}
  user1Id, user2Id, anniversary, createdAt
  ├── /events/{eventId}
  ├── /memes/{memeId}
  ├── /reminders/{reminderId}
  ├── /diary/{entryId}
  ├── /gameSessions/{sessionId}
  └── /thoughts/{thoughtId}

/locations/{userId}
  lat, lng, coupleId, updatedAt
```

**Ventajas:**
- Tiempo real nativo (Firestore listeners).
- Autenticación sin servidor.
- Push notifications sin servidor.
- Escala automática.
- **Costo: $0 para el MVP.**

---

## 4. Estructura del Proyecto Flutter

```
lib/
├── main.dart
├── firebase_options.dart                 # Generado por flutterfire configure
├── core/
│   ├── router/
│   │   └── app_router.dart              # go_router config
│   ├── services/
│   │   ├── auth_service.dart            # Firebase Auth wrapper
│   │   ├── firestore_service.dart       # Firestore wrapper (todos los módulos)
│   │   └── storage_service.dart         # Firebase Storage (imágenes)
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── widgets/                         # Widgets globales reutilizables
├── features/
│   ├── auth/
│   │   ├── presentation/pages/
│   │   │   ├── login_page.dart
│   │   │   ├── register_page.dart
│   │   │   └── pair_code_page.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart       # NotifierProvider con Firebase Auth
│   │   └── data/auth_repository.dart
│   ├── home/
│   │   └── presentation/pages/home_page.dart
│   ├── schedule/                        # StreamProvider → eventsStream
│   ├── memes/                           # StreamProvider → memesStream
│   ├── reminders/                       # StreamProvider → remindersStream
│   ├── distance/                        # StreamProvider → locationStream
│   ├── diary/                           # StreamProvider → diaryStream
│   ├── minigames/                       # StreamProvider → gameSessionsStream
│   └── thoughts/                        # StreamProvider → thoughtsStream
└── shared/models/
    └── user_model.dart
```

---

## 5. Firestore — Estructura de Datos

### Colecciones principales

```
firestore/
├── users/{userId}
│   ├── email: string
│   ├── name: string
│   ├── birthday: string (ISO date, opcional)
│   ├── fcmToken: string
│   ├── pairCode: string (6 chars, único)
│   ├── coupleId: string | null
│   ├── avatarUrl: string | null
│   └── createdAt: timestamp
│
├── pairCodes/{code}
│   └── userId: string
│
├── couples/{coupleId}
│   ├── user1Id: string
│   ├── user2Id: string
│   ├── anniversary: timestamp | null
│   └── createdAt: timestamp
│
├── couples/{coupleId}/events/{eventId}
│   ├── title: string
│   ├── description: string | null
│   ├── startAt: timestamp
│   ├── endAt: timestamp | null
│   ├── category: DATE | TRAVEL | SPECIAL | BIRTHDAY | ANNIVERSARY | OTHER
│   ├── reminderMinutes: number | null
│   ├── isRecurring: boolean
│   ├── createdBy: string (uid)
│   └── createdAt: timestamp
│
├── couples/{coupleId}/memes/{memeId}
│   ├── imageUrl: string (Firebase Storage URL)
│   ├── caption: string | null
│   ├── uploadedBy: string (uid)
│   ├── reactions: { emoji: [uid1, uid2] }
│   └── createdAt: timestamp
│
├── couples/{coupleId}/reminders/{reminderId}
│   ├── title: string
│   ├── description: string | null
│   ├── scheduledAt: timestamp
│   ├── targetUser: SELF | PARTNER | BOTH
│   ├── recurrence: NONE | DAILY | WEEKLY | MONTHLY | YEARLY
│   ├── isCompleted: boolean
│   ├── completedAt: timestamp | null
│   ├── createdBy: string (uid)
│   └── createdAt: timestamp
│
├── couples/{coupleId}/diary/{entryId}
│   ├── content: string
│   ├── mood: string (emoji)
│   ├── isPrivate: boolean
│   ├── entryDate: string (ISO date)
│   ├── authorId: string (uid)
│   ├── partnerReacted: boolean
│   └── createdAt: timestamp
│
├── couples/{coupleId}/gameSessions/{sessionId}
│   ├── gameType: TRUTH_OR_DARE | KNOW_ME | ROULETTE | STORY
│   ├── status: WAITING | IN_PROGRESS | FINISHED
│   ├── data: map (estado específico del juego)
│   └── createdAt: timestamp
│
├── couples/{coupleId}/thoughts/{thoughtId}
│   ├── content: string (máx 500 chars)
│   ├── tone: ROMANTIC | FUNNY | NOSTALGIC | URGENT
│   ├── senderId: string (uid)
│   ├── recipientId: string (uid)
│   ├── deliverAt: timestamp | null
│   ├── isDelivered: boolean
│   ├── isRead: boolean
│   ├── readAt: timestamp | null
│   ├── isFavorite: boolean
│   └── createdAt: timestamp
│
└── locations/{userId}
    ├── lat: number
    ├── lng: number
    ├── coupleId: string
    └── updatedAt: timestamp
```

### Índices recomendados

```
couples/{coupleId}/events    → startAt ASC
couples/{coupleId}/thoughts  → recipientId ASC, isDelivered ASC, createdAt DESC
couples/{coupleId}/reminders → isCompleted ASC, scheduledAt ASC
couples/{coupleId}/memes     → createdAt DESC
```

---

## 6. Módulos y Lógica de Vistas

---

### 6.1 Autenticación & Emparejamiento

#### Flujo
1. **Registro** → `FirebaseAuth.createUserWithEmailAndPassword()` → crea `/users/{uid}` con `pairCode` único de 6 chars → redirige a `PairCodePage`.
2. **Login** → `FirebaseAuth.signInWithEmailAndPassword()` → si tiene `coupleId` va a `HomePage`, si no va a `PairCodePage`.
3. **Emparejamiento** → lee `/pairCodes/{code}`, obtiene `partnerId`, crea `/couples/{id}`, actualiza ambos usuarios con `coupleId` en una batch write.

#### Provider
```dart
// NotifierProvider con Firebase Auth stream
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Escucha cambios en Auth y sincroniza documento Firestore del usuario
```

---

### 6.2 Cronograma

- **Stream:** `couples/{coupleId}/events` ordenado por `startAt`.
- **Widgets:** `TableCalendar` + lista de eventos del día seleccionado.
- **CRUD:** crear, editar y borrar eventos via `FirestoreService`.
- **Real-time:** cambios de uno se reflejan al otro instantáneamente.

---

### 6.3 Memes

- **Stream:** `couples/{coupleId}/memes` ordenado por `createdAt DESC`.
- **Upload:** `ImagePicker` → `FirebaseStorage` → URL guardada en Firestore.
- **Reacciones:** `FieldValue.arrayUnion([uid])` en `reactions.{emoji}`.
- **Grid:** 2 columnas, punto de color según quién subió.

---

### 6.4 Recordatorios

- **Stream:** `couples/{coupleId}/reminders` filtrado por `isCompleted = false`.
- **Swipe-to-complete:** marca `isCompleted: true` en Firestore.
- **Entrega diferida** (sin Cloud Functions): la app comprueba al abrirse si hay recordatorios vencidos y muestra notificación local.

---

### 6.5 Distancia

- **Ubicación propia:** `Geolocator.getCurrentPosition()` → escribe en `/locations/{uid}`.
- **Ubicación pareja:** stream de `/locations/{partnerId}`.
- **Cálculo:** Haversine en el cliente (sin servidor).
- **Corazón pulsante:** velocidad inversamente proporcional a la distancia.

---

### 6.6 Diario

- **Stream:** `couples/{coupleId}/diary` filtrado por visibilidad (`isPrivate = false OR authorId = uid`).
- **Reacción pareja:** `partnerReacted: true` via `reactDiaryEntry()`.
- **Privacidad:** entradas privadas solo visibles al autor.

---

### 6.7 Minijuegos

| Juego | Tipo | Implementación |
|---|---|---|
| Verdad o Reto | Asíncrono | Preguntas hardcodeadas en app, sesión en Firestore |
| Ruleta de planes | Stateless | Random en cliente, resultado guardado en Firestore |
| ¿Qué tan bien me conoces? | Síncrono | Firestore stream de `gameSessions/{id}` |
| Completar la historia | Asíncrono turnos | Documento de sesión en Firestore |

---

### 6.8 Pensamientos

- **Envío inmediato:** `isDelivered: true` al crear.
- **Envío diferido:** `isDelivered: false`, `deliverAt: timestamp` → la app verifica al abrirse.
- **Stream recibidos:** `recipientId = uid AND isDelivered = true`.
- **Stream enviados:** `senderId = uid`.
- **Tonos:** ROMANTIC 🌹 · FUNNY 😂 · NOSTALGIC 🌅 · URGENT 💌

---

## 7. Realtime Listeners & Sincronización

Todos los módulos usan `StreamProvider.autoDispose` con streams de Firestore:

```dart
final eventsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final coupleId = ref.watch(authProvider).coupleId;
  if (coupleId == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).eventsStream(coupleId);
});

// En el widget:
final eventsAsync = ref.watch(eventsProvider);
eventsAsync.when(
  data: (events) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

**Ventajas vs WebSockets manuales:**
- Sin servidor de WebSockets que mantener.
- Caché offline automático.
- Reconexión automática.
- Sin gestión de tokens de conexión.

---

## 8. Notificaciones Push (FCM)

```dart
// Guardar token al iniciar sesión
final token = await FirebaseMessaging.instance.getToken();
await firestoreService.updateUser(uid, {'fcmToken': token});

// Notificaciones en foreground
FirebaseMessaging.onMessage.listen((message) {
  FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    const NotificationDetails(...),
  );
});
```

Para notificaciones automáticas entre usuarios (ej: "tu pareja subió un meme"), se puede usar **Cloud Functions** en el plan Blaze (con capa gratuita de 125k invocaciones/mes).

---

## 9. Reglas de Seguridad (Firestore)

Ver archivo `firestore.rules` en la raíz del proyecto.

Puntos clave:
- Solo usuarios autenticados pueden acceder.
- Solo miembros de la pareja pueden leer/escribir datos de esa pareja.
- La función `isCoupleUser(coupleId)` verifica membresía en cada operación.
- Los memes y entradas de diario solo pueden borrarse por quien los creó.

Para desplegar las reglas:
```bash
firebase deploy --only firestore:rules
```

---

## 10. Plan de Desarrollo por Fases

### Fase 0 — Setup
- [x] Crear proyecto Firebase `alma-533d2`
- [x] Activar Auth (Email/Password), Firestore, Storage, Messaging
- [x] Ejecutar `flutterfire configure` → `firebase_options.dart` generado
- [x] Estructura Flutter completa
- [x] Servicios Firebase: `AuthService`, `FirestoreService`, `StorageService`

### Fase 1 — Autenticación ← EN PROGRESO
- [ ] Habilitar **Developer Mode** en Windows (para symlinks Flutter)
- [ ] `flutter pub get` sin errores
- [ ] Probar registro y login en Edge
- [ ] Probar emparejamiento con dos cuentas

### Fase 2 — Módulos básicos
- [ ] Cronograma funcional con datos reales en Firestore
- [ ] Recordatorios con CRUD completo
- [ ] Diario con entradas y reacciones

### Fase 3 — Módulos multimedia
- [ ] Memes con Firebase Storage
- [ ] Distancia con GPS real

### Fase 4 — Módulos avanzados
- [ ] Pensamientos con entrega diferida
- [ ] Minijuegos (Ruleta + Verdad o Reto)

### Fase 5 — Pulido & Deploy
- [ ] Animaciones y micro-interacciones
- [ ] Pruebas con dos dispositivos físicos
- [ ] APK para Android
- [ ] Publicar en Google Play

---

## 11. Dependencias Flutter

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Firebase
  firebase_core: ^4.9.0
  firebase_auth: ^6.5.1
  cloud_firestore: ^6.4.1
  firebase_storage: ^13.4.1
  firebase_messaging: ^16.2.2

  # Estado & Routing
  flutter_riverpod: ^3.3.1
  go_router: ^17.2.3

  # UI
  table_calendar: ^3.2.0
  cached_network_image: ^3.4.1
  intl: ^0.20.2

  # Multimedia
  image_picker: ^1.2.2
  geolocator: ^14.0.1
  flutter_map: ^8.3.0
  latlong2: ^0.9.1

  # Notificaciones locales
  flutter_local_notifications: ^21.0.0

  # Almacenamiento
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.5.5
  path_provider: ^2.1.5
```

---

## 12. Consideraciones Finales

### Límites del Plan Spark (Firebase gratuito)

| Recurso | Límite | MVP ALMA | ¿OK? |
|---|---|---|---|
| Firestore storage | 1 GB | ~50 MB | ✅ |
| Lecturas/día | 50,000 | ~5,000 | ✅ |
| Escrituras/día | 20,000 | ~2,000 | ✅ |
| Firebase Storage | 5 GB | ~1 GB (imágenes) | ✅ |
| Push notifications | Ilimitadas | ~100/día | ✅ |
| **Costo total** | | | **$0** |

### Identidad visual
- **Nombre:** ALMA
- **Paleta:** coral `#E07A5F` · rosa `#F4A261` · beige `#FFF8F5` · verde salvia `#81B29A`
- **Tipografía:** Playfair Display (títulos) + Inter (UI)

### Features de segunda iteración
- Álbum de fotos compartido (Firebase Storage).
- Contador de racha de uso diario.
- Widget de pantalla de inicio.
- Backup del diario en PDF.
- Chat en tiempo real (si los usuarios lo piden).

---

*ALMA — v2.0 · Firebase + Flutter · 2026-06-01*
