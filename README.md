# Ship Supply Management System (SSMS)

Gemi Kumanyacılığı ERP - Denizcilik sektörü için teklif, sipariş ve tedarik zinciri yönetim sistemi.

## 🚀 Teknoloji Stack

| Katman | Teknoloji | Açıklama |
|--------|-----------|----------|
| **Frontend** | Flutter (Dart) | Windows, macOS ve iOS için cross-platform uygulama |
| **Backend** | Rust + Axum | Yüksek performanslı REST API sunucusu |
| **Veritabanı** | PostgreSQL | Production veritabanı (SQLite local dev için) |
| **ORM** | SeaORM | Tip güvenli SQL sorguları |

## 📋 Özellikler

- 🚢 Gemi yönetimi (IMO numarası, bayrak, tonaj)
- 📦 Sipariş yönetimi (durum takibi, teslimat)
- 💰 Kar/Zarar analizi (alış/satış fiyatı takibi)
- 👥 Tedarikçi yönetimi
- 📊 Excel benzeri veri girişi (PlutoGrid)

## 🏁 Başlangıç

### Gereksinimler

- [Rust](https://rustup.rs/) (latest stable)
- [Flutter](https://flutter.dev/docs/get-started/install) (3.x+)
- [Docker](https://www.docker.com/) (PostgreSQL için)

### Kurulum

1. **Veritabanını başlat:**
```bash
docker-compose up -d postgres
```

2. **Backend'i çalıştır:**
```bash
cd backend
cp .env.example .env
cargo run
```

3. **Frontend'i çalıştır:**
```bash
cd frontend
flutter pub get
flutter run -d windows  # veya macos, ios
```

## 📁 Proje Yapısı

```
├── backend/                 # Rust API sunucusu
│   ├── src/
│   │   ├── entities/       # SeaORM entity tanımları
│   │   ├── handlers/       # HTTP request handlers
│   │   ├── services/       # İş mantığı
│   │   ├── config.rs       # Konfigürasyon
│   │   ├── main.rs         # Uygulama entry point
│   │   ├── response.rs     # API response wrapper
│   │   └── routes.rs       # Route tanımları
│   └── Cargo.toml
│
├── frontend/               # Flutter uygulaması
│   ├── lib/
│   │   ├── core/          # Ortak bileşenler
│   │   │   ├── network/   # API client
│   │   │   ├── router/    # Navigation
│   │   │   ├── theme/     # UI tema
│   │   │   └── widgets/   # Ortak widget'lar
│   │   └── features/      # Özellik modülleri
│   │       ├── dashboard/
│   │       ├── orders/
│   │       ├── ships/
│   │       └── suppliers/
│   └── pubspec.yaml
│
├── docker/                 # Docker konfigürasyonları
│   └── init.sql           # Veritabanı şeması
│
└── docker-compose.yml
```

## 🔌 API Endpoints

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| GET | `/api/ships` | Tüm gemileri listele |
| POST | `/api/ships` | Yeni gemi ekle |
| GET | `/api/orders` | Tüm siparişleri listele |
| POST | `/api/orders` | Yeni sipariş oluştur |
| PUT | `/api/orders/{id}/status` | Sipariş durumu güncelle |
| GET | `/api/suppliers` | Tedarikçileri listele |

## 📊 Sipariş Durumu Akışı

```
NEW → QUOTED → AGREED → WAITING_GOODS → PREPARED → ON_WAY → DELIVERED → INVOICED
                                                                    ↓
                                                               CANCELLED
```

## 💹 Kar Hesaplama

```
Brüt Kar = (Satış Fiyatı - Alış Fiyatı) × Miktar
Marj (%) = ((Satış Fiyatı - Alış Fiyatı) / Satış Fiyatı) × 100
```

## 🛠 Geliştirme

### Backend testleri
```bash
cd backend
cargo test
```

### Flutter kod üretimi (freezed, json_serializable)
```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

## 📝 Lisans

MIT License
