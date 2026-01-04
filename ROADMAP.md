# 🚢 Ship Supply Management System (SSMS) - Proje Yol Haritası

> **Son Güncelleme:** 4 Ocak 2026  
> **Proje Durumu:** 🟡 Aktif Geliştirme (Faz 1)

---

## 📋 İçindekiler

- [Proje Vizyonu](#-proje-vizyonu)
- [Mevcut Durum](#-mevcut-durum)
- [Faz 1: Temel Altyapı](#-faz-1-temel-altyapı-q1-2026)
- [Faz 2: Çekirdek İş Mantığı](#-faz-2-çekirdek-iş-mantığı-q2-2026)
- [Faz 3: Gelişmiş Özellikler](#-faz-3-gelişmiş-özellikler-q3-2026)
- [Faz 4: iOS & Optimizasyon](#-faz-4-ios--optimizasyon-q4-2026)
- [Faz 5: Üretime Hazırlık](#-faz-5-üretime-hazırlık-q1-2027)
- [Teknik Borç & İyileştirmeler](#-teknik-borç--iyileştirmeler)
- [Risk Analizi](#-risk-analizi)

---

## 🎯 Proje Vizyonu

SSMS, gemi kumanyacılığı (ship chandler) operasyonlarını dijitalleştiren, Windows masaüstü ve iOS mobil platformlarda çalışan hibrit bir ERP sistemidir.

### Hedef Kullanıcılar
| Kullanıcı Tipi | Platform | Ana Görevler |
|----------------|----------|--------------|
| Operasyon Personeli | Windows | Sipariş girişi, fiyatlandırma, stok yönetimi |
| Satın Alma | Windows | Tedarikçi yönetimi, maliyet analizi |
| Yönetici | iOS | Onay/Red, dashboard, raporlar |
| Saha Personeli | iOS | Teslimat takibi, durum güncelleme |

### Temel Değer Önerileri
- ⚡ **Hız:** Rust backend ile yüksek performanslı hesaplamalar
- 📱 **Mobilite:** iOS'ta yönetici onay/takip sistemi
- 💰 **Karlılık Takibi:** Gerçek zamanlı maliyet/gelir analizi
- 🔄 **Offline Çalışma:** SQLite ile yerel veri senkronizasyonu

---

## ✅ Mevcut Durum

### Tamamlanan İşler
- [x] Proje yapısı ve mimari tasarım
- [x] Flutter frontend scaffolding (Windows)
- [x] Rust backend temel yapısı
- [x] "Linear Aesthetic" UI tasarım sistemi
- [x] Platform-adaptive layout (Windows/iOS)
- [x] Navigation sistemi (go_router)
- [x] Operasyon Takvimi modülü (Syncfusion Calendar)
- [x] Temel sayfalar (Dashboard, Orders, Ships, Suppliers, Calendar)
- [x] OrderStatus state machine tasarımı
- [x] SeaORM entity tanımlamaları

### Bekleyen Kritik İşler
- [ ] Flutter Rust Bridge (FRB) entegrasyonu
- [ ] PostgreSQL veritabanı bağlantısı
- [ ] CRUD operasyonları
- [ ] Kimlik doğrulama sistemi

---

## 🔷 Faz 1: Temel Altyapı (Q1 2026)

### 1.1 Flutter Rust Bridge Kurulumu
**Süre:** 2 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| FRB v2 konfigürasyonu | ⬜ | `flutter_rust_bridge_codegen` kurulumu |
| Rust library derleme | ⬜ | `cdylib` + `staticlib` output |
| Dart binding oluşturma | ⬜ | Otomatik kod üretimi |
| Windows entegrasyonu | ⬜ | DLL yükleme ve FFI bağlantısı |
| Temel API testleri | ⬜ | Ping/pong, basit veri transferi |

**Teknik Detaylar:**
```yaml
# flutter_rust_bridge.yaml
rust_input: backend/src/api.rs
dart_output: frontend/lib/src/rust/
c_output: frontend/rust/
```

### 1.2 Veritabanı Altyapısı
**Süre:** 2 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| PostgreSQL Docker setup | ⬜ | docker-compose.yml güncelleme |
| SeaORM migration sistemi | ⬜ | `sea-orm-cli` ile migration |
| Entity relationship'ler | ⬜ | Foreign key tanımlamaları |
| Connection pool | ⬜ | `sqlx` pool konfigürasyonu |
| SQLite offline cache | ⬜ | Yerel veritabanı yapısı |

**Veritabanı Şeması:**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Ship     │────<│    Order    │>────│  Supplier   │
└─────────────┘     └──────┬──────┘     └─────────────┘
                          │
                    ┌─────┴─────┐
                    │ OrderItem │>────┌─────────────┐
                    └───────────┘     │ SupplyItem  │
                                      └─────────────┘
┌─────────────┐     ┌─────────────┐
│    Port     │────<│  ShipVisit  │
└─────────────┘     └─────────────┘
```

### 1.3 Kimlik Doğrulama Sistemi
**Süre:** 1 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| User entity | ⬜ | Kullanıcı modeli |
| JWT token sistemi | ⬜ | `jsonwebtoken` crate |
| Login ekranı (Flutter) | ⬜ | Email/şifre formu |
| Role-based access | ⬜ | Admin, Manager, Operator rolleri |
| Secure storage | ⬜ | Token saklama (flutter_secure_storage) |

---

## 🔶 Faz 2: Çekirdek İş Mantığı (Q2 2026)

### 2.1 Gemi Yönetimi (Ships Module)
**Süre:** 2 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Ship CRUD API (Rust) | ⬜ | create, read, update, delete |
| Ship list UI (PlutoGrid) | ⬜ | Windows data grid |
| Ship detail sayfası | ⬜ | Detay görüntüleme |
| Ship form (create/edit) | ⬜ | Form validasyonu |
| IMO doğrulama | ⬜ | IMO numarası format kontrolü |
| Ship arama/filtreleme | ⬜ | Bayrak, isim, IMO ile arama |

**Ship Entity Alanları:**
```rust
pub struct Ship {
    pub id: i32,
    pub name: String,
    pub imo_number: String,      // 7 haneli, benzersiz
    pub flag: String,            // Ülke kodu (TR, PA, LR, etc.)
    pub ship_type: ShipType,     // Bulk, Tanker, Container, etc.
    pub gross_tonnage: Option<i32>,
    pub owner_company: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub notes: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime,
    pub updated_at: DateTime,
}
```

### 2.2 Sipariş Yönetimi (Orders Module)
**Süre:** 4 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Order CRUD API | ⬜ | Sipariş işlemleri |
| OrderItem CRUD API | ⬜ | Sipariş kalemleri |
| Order list UI | ⬜ | Durum filtreleriyle liste |
| Order detail sayfası | ⬜ | Kalemler ve özet |
| Order form wizard | ⬜ | Adım adım sipariş oluşturma |
| Status transition API | ⬜ | Durum geçiş validasyonu |
| Status history | ⬜ | Durum değişiklik logu |
| Order PDF export | ⬜ | Proforma/fatura PDF |

**Sipariş Durumu Akışı:**
```
┌─────┐    ┌────────┐    ┌────────┐    ┌──────────────┐
│ NEW │───>│ QUOTED │───>│ AGREED │───>│ WAITING_GOODS│
└─────┘    └────────┘    └────────┘    └──────┬───────┘
                                              │
┌──────────┐    ┌────────┐    ┌──────────┐    │
│ INVOICED │<───│DELIVERED│<───│  ON_WAY  │<───┘
└──────────┘    └────────┘    └──────────┘
                    │
              ┌─────┴─────┐
              │ PREPARED  │
              └───────────┘
```

### 2.3 Tedarikçi Yönetimi (Suppliers Module)
**Süre:** 2 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Supplier CRUD API | ⬜ | Tedarikçi işlemleri |
| Supplier list UI | ⬜ | PlutoGrid ile liste |
| Supplier detail | ⬜ | İletişim bilgileri, geçmiş |
| Supplier categories | ⬜ | Kategori bazlı gruplama |
| Supplier rating | ⬜ | Performans puanlama |
| Contact management | ⬜ | Çoklu iletişim kişisi |

### 2.4 Ürün/Malzeme Yönetimi (Supply Items Module)
**Süre:** 2 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| SupplyItem CRUD API | ⬜ | Ürün kataloğu |
| Category hierarchy | ⬜ | Kategori/alt kategori yapısı |
| Unit management | ⬜ | Birim tanımları (kg, lt, adet) |
| Price history | ⬜ | Fiyat değişiklik takibi |
| Barcode/SKU support | ⬜ | Ürün kodu sistemi |
| Image upload | ⬜ | Ürün görselleri |

### 2.5 Karlılık Hesaplama Servisi
**Süre:** 1 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Item profit calculation | ⬜ | Satış - Maliyet |
| Order total calculation | ⬜ | Toplam gelir/maliyet/kar |
| Profit margin % | ⬜ | Kar marjı hesaplama |
| Currency conversion | ⬜ | USD/EUR/TRY dönüşüm |
| Profit reports | ⬜ | Dönemsel karlılık raporu |

**Hesaplama Formülleri:**
```rust
// Kalem bazlı kar
item_profit = (selling_price - buying_price) * quantity

// Sipariş toplam karı
order_profit = Σ item_profits

// Kar marjı
profit_margin = (order_profit / total_revenue) * 100
```

---

## 🟢 Faz 3: Gelişmiş Özellikler (Q3 2026)

### 3.1 Liman & Ziyaret Yönetimi
**Süre:** 2 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Port CRUD API | ⬜ | Liman yönetimi |
| ShipVisit CRUD API | ⬜ | Ziyaret planlama |
| Calendar FFI entegrasyonu | ⬜ | Rust'tan veri çekme |
| Drag & drop rescheduling | ⬜ | Takvimde sürükle-bırak |
| Visit notifications | ⬜ | Yaklaşan ziyaret bildirimi |
| Port capacity planning | ⬜ | Liman yoğunluk görünümü |

### 3.2 Raporlama & Analytics
**Süre:** 3 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Dashboard widgets | ⬜ | KPI kartları |
| Sales charts | ⬜ | Satış grafikleri (fl_chart) |
| Profit trends | ⬜ | Karlılık trendi |
| Top ships report | ⬜ | En çok sipariş veren gemiler |
| Supplier performance | ⬜ | Tedarikçi performans raporu |
| Export to Excel | ⬜ | Rapor dışa aktarma |

**Dashboard KPI'ları:**
- Toplam Sipariş (Bu ay/Geçen ay)
- Toplam Gelir (TRY/USD)
- Ortalama Kar Marjı (%)
- Aktif Gemiler
- Bekleyen Siparişler
- Yaklaşan Ziyaretler (7 gün)

### 3.3 Arama & Filtreleme Altyapısı
**Süre:** 1 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Global search | ⬜ | Tüm modüllerde arama |
| Advanced filters | ⬜ | Çoklu kriter filtreleme |
| Saved filters | ⬜ | Filtre kaydetme |
| Recent searches | ⬜ | Son aramalar |
| Search suggestions | ⬜ | Otomatik tamamlama |

### 3.4 Bildirim Sistemi
**Süre:** 2 hafta | **Öncelik:** 🟢 Orta

| Görev | Durum | Açıklama |
|-------|-------|----------|
| In-app notifications | ⬜ | Uygulama içi bildirim |
| Notification center UI | ⬜ | Bildirim merkezi |
| Push notifications (iOS) | ⬜ | APNs entegrasyonu |
| Email notifications | ⬜ | Kritik durumlar için email |
| Notification preferences | ⬜ | Kullanıcı tercihleri |

### 3.5 Dosya Yönetimi
**Süre:** 2 hafta | **Öncelik:** 🟢 Orta

| Görev | Durum | Açıklama |
|-------|-------|----------|
| File upload API | ⬜ | Dosya yükleme servisi |
| Document attachment | ⬜ | Siparişe belge ekleme |
| Image compression | ⬜ | Görsel optimizasyonu |
| S3/MinIO storage | ⬜ | Bulut depolama |
| File preview | ⬜ | PDF/Image önizleme |

---

## 🍎 Faz 4: iOS & Optimizasyon (Q4 2026)

### 4.1 iOS Platform Desteği
**Süre:** 4 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Rust static library (iOS) | ⬜ | arm64 derleme |
| CocoaPods entegrasyonu | ⬜ | iOS dependency management |
| iOS UI polish | ⬜ | Cupertino widgets |
| App Store hazırlık | ⬜ | Screenshots, açıklama |
| TestFlight beta | ⬜ | Beta test dağıtımı |

**iOS Özel Özellikler:**
- Face ID / Touch ID ile giriş
- Push notification desteği
- Offline mode (SQLite sync)
- Share extension (belge paylaşımı)

### 4.2 Offline & Sync Sistemi
**Süre:** 3 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| SQLite local database | ⬜ | Yerel veri yapısı |
| Conflict resolution | ⬜ | Çakışma çözümleme stratejisi |
| Background sync | ⬜ | Arka plan senkronizasyonu |
| Sync status UI | ⬜ | Senkronizasyon durumu göstergesi |
| Offline queue | ⬜ | Çevrimdışı işlem kuyruğu |

**Sync Stratejisi:**
```
┌─────────────────┐
│  Local SQLite   │
│  (iOS/Windows)  │
└────────┬────────┘
         │ Sync
         ▼
┌─────────────────┐
│   PostgreSQL    │
│    (Server)     │
└─────────────────┘
```

### 4.3 Performans Optimizasyonu
**Süre:** 2 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Query optimization | ⬜ | SQL sorgu optimizasyonu |
| Lazy loading | ⬜ | Veri pagination |
| Image caching | ⬜ | Görsel önbellekleme |
| Memory profiling | ⬜ | Bellek kullanım analizi |
| Startup time | ⬜ | Uygulama açılış süresi |

### 4.4 Güvenlik Hardening
**Süre:** 2 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| API rate limiting | ⬜ | İstek sınırlama |
| Input sanitization | ⬜ | SQL injection koruması |
| HTTPS enforcing | ⬜ | SSL/TLS zorunluluğu |
| Audit logging | ⬜ | İşlem kayıt logu |
| Data encryption | ⬜ | Hassas veri şifreleme |

---

## 🚀 Faz 5: Üretime Hazırlık (Q1 2027)

### 5.1 Test & QA
**Süre:** 3 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Unit tests (Rust) | ⬜ | Backend birim testleri |
| Widget tests (Flutter) | ⬜ | UI birim testleri |
| Integration tests | ⬜ | Entegrasyon testleri |
| E2E tests | ⬜ | Uçtan uca testler |
| Performance tests | ⬜ | Yük testleri |
| Security audit | ⬜ | Güvenlik denetimi |

**Test Hedefleri:**
- Kod kapsama: > 80%
- API yanıt süresi: < 100ms
- UI FPS: > 60fps
- Crash rate: < 0.1%

### 5.2 DevOps & CI/CD
**Süre:** 2 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| GitHub Actions workflow | ⬜ | Otomatik build/test |
| Docker production images | ⬜ | Production container |
| Kubernetes deployment | ⬜ | K8s manifest'leri |
| Database migrations | ⬜ | Otomatik migration |
| Environment management | ⬜ | Dev/Staging/Prod ortamları |

### 5.3 Dokümantasyon
**Süre:** 2 hafta | **Öncelik:** 🟡 Yüksek

| Görev | Durum | Açıklama |
|-------|-------|----------|
| API documentation | ⬜ | OpenAPI/Swagger |
| User manual | ⬜ | Kullanıcı kılavuzu |
| Admin guide | ⬜ | Yönetici kılavuzu |
| Developer docs | ⬜ | Geliştirici dökümantasyonu |
| Video tutorials | ⬜ | Eğitim videoları |

### 5.4 Deployment & Monitoring
**Süre:** 2 hafta | **Öncelik:** 🔴 Kritik

| Görev | Durum | Açıklama |
|-------|-------|----------|
| Production deployment | ⬜ | Canlıya alma |
| Health monitoring | ⬜ | Sistem sağlık izleme |
| Error tracking | ⬜ | Sentry entegrasyonu |
| Analytics | ⬜ | Kullanım analitiği |
| Backup & restore | ⬜ | Yedekleme prosedürü |

---

## 🔧 Teknik Borç & İyileştirmeler

### Kod Kalitesi
- [ ] Lint kuralları standardizasyonu
- [ ] Code review checklist
- [ ] Refactoring planı
- [ ] Dependency güncelleme politikası

### Mimari İyileştirmeler
- [ ] State management optimizasyonu
- [ ] Error handling standardizasyonu
- [ ] Logging framework
- [ ] Feature flag sistemi

### UX İyileştirmeler
- [ ] Loading state animasyonları
- [ ] Error message iyileştirmesi
- [ ] Keyboard shortcuts (Windows)
- [ ] Accessibility (a11y) desteği

---

## ⚠️ Risk Analizi

| Risk | Olasılık | Etki | Azaltma Stratejisi |
|------|----------|------|-------------------|
| FRB versiyon uyumsuzluğu | Orta | Yüksek | Pin version, migration planı |
| iOS App Store reddi | Düşük | Yüksek | Guideline takibi, beta test |
| Performans sorunları | Orta | Orta | Erken optimizasyon, profiling |
| Veri kaybı | Düşük | Kritik | Backup, transaction log |
| Syncfusion lisans | Düşük | Orta | Community license, alternatif |

---

## 📊 Zaman Çizelgesi Özeti

```
2026 Q1  ████████████████████████████████  Faz 1: Temel Altyapı
2026 Q2  ████████████████████████████████  Faz 2: Çekirdek İş Mantığı  
2026 Q3  ████████████████████████████████  Faz 3: Gelişmiş Özellikler
2026 Q4  ████████████████████████████████  Faz 4: iOS & Optimizasyon
2027 Q1  ████████████████████████████████  Faz 5: Üretime Hazırlık
```

---

## 📞 İletişim & Kaynaklar

- **Proje Deposu:** [GitHub - SSMS]
- **Tasarım Dosyaları:** [Figma - SSMS Design System]
- **API Dokümantasyonu:** [Swagger - SSMS API]

---

> 💡 **Not:** Bu roadmap yaşayan bir dokümandır. Sprint planlaması ve önceliklendirme iş gereksinimlerine göre güncellenebilir.
