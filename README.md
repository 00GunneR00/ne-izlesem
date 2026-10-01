# Ne İzlesem

"Bu akşam ne izlesek?" sorusunu tek başına, arkadaşlarınla ya da grupça çözen film ve dizi uygulaması. Kartları kaydırarak beğendiklerini seçersin; uygulama zevkine göre öneri yapar, arkadaş grubunda herkesin "evet" dediği yapımları bulur ve izleme planını takip eder.

Depo iki parçadan oluşur: Flutter ile yazılmış mobil uygulama ve ASP.NET Core ile yazılmış API. Film ve dizi verisi [TMDB](https://www.themoviedb.org/) üzerinden gelir.

## Özellikler

**Keşfet ve kaydır**
- Kaydırmalı kart destesi: beğen ya da geç. Daha önce karar verdiğin yapımlar tekrar gösterilmez.
- Keşfet akışı, fragman oynatıcı (YouTube) ve tür tercihleri
- "Senin İçin": puanlarına, beğenilerine ve izleme geçmişine göre öneriler

**Arama**
- Film, dizi ve kişi araması; oyuncu ve yönetmen filmografisi
- Platforma göre arama (Türkiye'deki yayın platformları)

**Kütüphane ve takip**
- İzledim / izleyeceğim / izliyorum durumları, 1-5 yıldız kişisel puan
- Diziler için sezon ve bölüm ilerlemesi
- Kendi listelerini oluşturma

**Sosyal**
- Arkadaş ekleme, arkadaşlara film ve dizi önerme
- Yorumlar: düzenleme, silme ve spoiler işareti
- Bildirimler; dokununca ilgili ekrana gider

**Gruplar**
- "Birlikte Seç": grubun ortak kaydırma destesi, herkesin beğendikleri eşleşme olur
- Eşleşmelerde oylama (İzleyelim / Kararsız / İzlemeyelim) ve sıralı liste
- Film / dizi filtresi, grubun önerileri

**Plan**
- İzleme planı oluşturma, davetlilerin katılım yanıtı
- "Bu Hafta" ajandası; tek başına, grupla ve arkadaşlarla sekmeleri
- İzledikten sonra "Nasıldı?" değerlendirmesi

**Hesap**
- E-posta ve şifreyle kayıt/giriş, JWT oturumu
- Uygulama içinden hesap silme

## Teknolojiler

| Katman | Kullanılanlar |
|---|---|
| Mobil | Flutter, GetX (durum yönetimi ve yönlendirme), Dio, flutter_secure_storage, cached_network_image, youtube_player_flutter |
| API | ASP.NET Core 9 (Web API), Entity Framework Core, JWT Bearer, Swagger |
| Veritabanı | PostgreSQL 16 (Docker) |
| Dış servis | TMDB API |

## Klasör yapısı

```
backend/             ASP.NET Core API
  Controllers/       Uç noktalar (auth, swipe, feed, gruplar, planlar...)
  Services/          TMDB istemcisi, deste ve eşleşme mantığı, kimlik doğrulama
  Models/ DTOs/      Varlıklar ve veri aktarım nesneleri
  Migrations/        EF Core göçleri
mobile/              Flutter uygulaması
  lib/core/          Ağ katmanı, oturum, tema, rotalar
  lib/data/          Modeller ve API servisleri
  lib/features/      Ekranlar (discover, swipe, groups, takip, social...)
docker-compose.yml   Yerel PostgreSQL
```

## Kurulum

Gerekenler: Flutter SDK, .NET 9 SDK, Docker ve bir TMDB API anahtarı.

### 1. Veritabanı

```sh
docker compose up -d
```

PostgreSQL `localhost:5433` üzerinde açılır.

### 2. API

Gizli değerler depoda tutulmaz; `user-secrets` ile verilir:

```sh
cd backend
dotnet user-secrets set "Tmdb:ReadAccessToken" "<TMDB okuma anahtarın>"
dotnet user-secrets set "Jwt:Key" "<en az 32 baytlık rastgele bir anahtar>"
dotnet ef database update
dotnet run
```

API `http://localhost:5292` adresinde çalışır, Swagger arayüzü `/swagger` altındadır. Canlı ortamda aynı değerler `Tmdb__ReadAccessToken` ve `Jwt__Key` ortam değişkenleriyle verilir.

### 3. Mobil uygulama

```sh
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5292/api
```

`10.0.2.2`, Android emülatöründen bilgisayarın `localhost` adresine erişmek içindir. Gerçek telefonda bilgisayarın yerel ağ adresini yaz.

## TMDB

Bu ürün TMDB API'sini kullanır ancak TMDB tarafından onaylanmamış ya da sertifikalandırılmamıştır.

## Lisans

Tüm hakları saklıdır. Bu depodaki kod izinsiz kopyalanamaz, dağıtılamaz ve kullanılamaz.
